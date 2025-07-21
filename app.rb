require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load'

# Add some startup logging
puts "Starting gh-commenter app..."
puts "RACK_ENV: #{ENV['RACK_ENV']}"
puts "PORT: #{ENV['PORT']}"
puts "Environment variables loaded: #{ENV.keys.grep(/GITHUB|SLACK/).join(', ')}"

helpers do
  def json(response_hash)
    content_type :json
    response_hash.to_json
  end
end

get '/up' do
  status 200
  'OK'
end

post '/ghcomment' do
  issue_url = params['text']&.strip
  channel_id = params['channel_id']
  thread_ts = params['thread_ts'] || params['message_ts']

  halt 400, "Missing thread." unless thread_ts

  messages = get_thread_messages(channel_id, thread_ts)
  thread_text = messages.map { |m|
    text = m['text'] || ''
    # Decode HTML entities that Slack uses
    text = text.gsub('&gt;', '>')
               .gsub('&lt;', '<')
               .gsub('&amp;', '&')
               .gsub('&quot;', '"')
               .gsub('&#39;', "'")

    # Use real name if available, otherwise fall back to user ID
    user_display = m['user_name'] || m['user'] || 'unknown'

    "**#{user_display}**: #{text}"
  }.join("\n\n")

  if issue_url =~ %r{github\.com/([^/]+)/([^/]+)/issues/(\d+)}
    org, repo, issue_number = $1, $2, $3
  else
    halt 400, "Invalid GitHub issue URL."
  end

  comment_url = github_comment(issue_number, org, repo, thread_text)
  post_slack_reply(channel_id, thread_ts, comment_url)

  status 200
  "✅ Posted to GitHub: #{comment_url}"
end

post '/message-shortcut' do
  request.body.rewind
  raw_payload = request.body.read
  parsed = URI.decode_www_form(raw_payload).to_h
  payload = JSON.parse(parsed['payload'])

  if payload['type'] == 'message_action'
    # Message shortcuts have access to message context automatically
    trigger_id = payload['trigger_id']
    channel_id = payload.dig('channel', 'id')
    message_ts = payload.dig('message', 'ts')
    thread_ts = payload.dig('message', 'thread_ts') || message_ts
    
    puts "DEBUG: Message shortcut - Channel: #{channel_id}, Thread: #{thread_ts}"

    view = {
      type: "modal",
      callback_id: "gh_comment_modal_message",
      title: { type: "plain_text", text: "Post Thread to GitHub" },
      submit: { type: "plain_text", text: "Post" },
      close: { type: "plain_text", text: "Cancel" },
      private_metadata: JSON.generate({
        channel_id: channel_id,
        thread_ts: thread_ts
      }),
      blocks: [
        {
          type: "section",
          text: { type: "mrkdwn", text: "This will post the entire thread to a GitHub issue." }
        },
        {
          type: "input",
          block_id: "issue_block",
          label: { type: "plain_text", text: "GitHub Issue URL" },
          element: {
            type: "plain_text_input",
            action_id: "issue_url",
            placeholder: { type: "plain_text", text: "https://github.com/org/repo/issues/123" }
          }
        }
      ]
    }

    uri = URI("https://slack.com/api/views.open")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{ENV['SLACK_BOT_TOKEN']}"
    req['Content-Type'] = 'application/json'
    req.body = { trigger_id: trigger_id, view: view }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    status res.code.to_i
    body res.body

  elsif payload['type'] == 'view_submission'
    metadata = JSON.parse(payload.dig('view', 'private_metadata'))
    channel_id = metadata['channel_id']
    thread_ts = metadata['thread_ts']
    issue_url = payload.dig('view', 'state', 'values', 'issue_block', 'issue_url', 'value')

    puts "DEBUG: Message modal submission - Issue: #{issue_url}"

    unless issue_url =~ %r{github\.com/([^/]+)/([^/]+)/issues/(\d+)}
      status 200
      return json(response_action: 'errors', errors: { issue_block: 'Invalid GitHub issue URL.' })
    end

    org, repo, issue_number = $1, $2, $3

    messages = get_thread_messages(channel_id, thread_ts)
    thread_text = messages.map { |m|
      text = m['text'] || ''
      # Decode HTML entities that Slack uses
      text = text.gsub('&gt;', '>')
                 .gsub('&lt;', '<')
                 .gsub('&amp;', '&')
                 .gsub('&quot;', '"')
                 .gsub('&#39;', "'")

      # Use real name if available, otherwise fall back to user ID
      user_display = m['user_name'] || m['user'] || 'unknown'

      "**#{user_display}**: #{text}"
    }.join("\n\n")

    if thread_text.strip.empty?
      status 200
      return json(response_action: 'errors', errors: { issue_block: 'No messages found in that thread.' })
    end

    comment_url = github_comment(issue_number, org, repo, thread_text)
    post_slack_reply(channel_id, thread_ts, comment_url)

    status 200
    body '' # Required response for modals
  else
    halt 400, "Unsupported payload type for message shortcut"
  end
end

post '/shortcut' do
  request.body.rewind
  raw_payload = request.body.read
  parsed = URI.decode_www_form(raw_payload).to_h
  payload = JSON.parse(parsed['payload'])

  if payload['type'] == 'shortcut'
    # Open a modal to collect both Slack thread URL and GitHub issue URL
    trigger_id = payload['trigger_id']
    puts "DEBUG: Global shortcut triggered"

    view = {
      type: "modal",
      callback_id: "gh_comment_modal",
      title: { type: "plain_text", text: "Post Thread to GitHub" },
      submit: { type: "plain_text", text: "Post" },
      close: { type: "plain_text", text: "Cancel" },
      private_metadata: "{}",
      blocks: [
        {
          type: "section",
          text: { type: "mrkdwn", text: "To get the thread URL: Right-click on any message in the thread → *Copy link*" }
        },
        {
          type: "input",
          block_id: "thread_block",
          label: { type: "plain_text", text: "Slack Thread URL" },
          element: {
            type: "plain_text_input",
            action_id: "thread_url",
            placeholder: { type: "plain_text", text: "Paste the thread link here..." }
          }
        },
        {
          type: "input",
          block_id: "issue_block",
          label: { type: "plain_text", text: "GitHub Issue URL" },
          element: {
            type: "plain_text_input",
            action_id: "issue_url",
            placeholder: { type: "plain_text", text: "https://github.com/org/repo/issues/123" }
          }
        }
      ]
    }

    uri = URI("https://slack.com/api/views.open")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{ENV['SLACK_BOT_TOKEN']}"
    req['Content-Type'] = 'application/json'
    req.body = { trigger_id: trigger_id, view: view }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    status res.code.to_i
    body res.body

  elsif payload['type'] == 'view_submission'
    thread_url = payload.dig('view', 'state', 'values', 'thread_block', 'thread_url', 'value')
    issue_url = payload.dig('view', 'state', 'values', 'issue_block', 'issue_url', 'value')

    puts "DEBUG: Thread URL: #{thread_url}"
    puts "DEBUG: Issue URL: #{issue_url}"

    # Parse Slack thread URL - handles multiple formats
    if thread_url =~ %r{https://[\w-]+\.slack\.com/archives/([^/]+)/p(\d+)(?:\?thread_ts=(\d+\.\d+))?}
      channel_id = $1
      message_ts = "#{$2[0..-7]}.#{$2[-6..-1]}"
      thread_ts = $3 || message_ts
    else
      status 200
      return json(response_action: 'errors', errors: { thread_block: 'Invalid Slack URL format. Please copy the link from a message in the thread.' })
    end

    puts "DEBUG: Parsed Channel: #{channel_id}, Thread: #{thread_ts}"

    unless issue_url =~ %r{github\.com/([^/]+)/([^/]+)/issues/(\d+)}
      status 200
      return json(response_action: 'errors', errors: { issue_block: 'Invalid GitHub issue URL.' })
    end

    org, repo, issue_number = $1, $2, $3

    messages = get_thread_messages(channel_id, thread_ts)
    thread_text = messages.map { |m|
      text = m['text'] || ''
      # Decode HTML entities that Slack uses
      text = text.gsub('&gt;', '>')
                 .gsub('&lt;', '<')
                 .gsub('&amp;', '&')
                 .gsub('&quot;', '"')
                 .gsub('&#39;', "'")

      # Use real name if available, otherwise fall back to user ID
      user_display = m['user_name'] || m['user'] || 'unknown'

      "**#{user_display}**: #{text}"
    }.join("\n\n")

    puts "DEBUG: Channel: #{channel_id}, Thread: #{thread_ts}, Messages: #{messages.length}, Text: '#{thread_text[0..100]}'"

    if thread_text.strip.empty?
      status 200
      return json(response_action: 'errors', errors: { thread_block: 'No messages found in that thread.' })
    end

    comment_url = github_comment(issue_number, org, repo, thread_text)
    post_slack_reply(channel_id, thread_ts, comment_url)

    status 200
    body '' # Required response for modals
  else
    halt 400, "Unsupported payload type"
  end
end

def get_thread_messages(channel, thread_ts)
  uri = URI("https://slack.com/api/conversations.replies?channel=#{channel}&ts=#{thread_ts}")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{ENV['SLACK_BOT_TOKEN']}"
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  response = JSON.parse(res.body)
  messages = response['messages'] || []

  # Get user info for all unique users in the thread
  user_ids = messages.map { |m| m['user'] }.compact.uniq
  user_names = {}

  user_ids.each do |user_id|
    user_uri = URI("https://slack.com/api/users.info?user=#{user_id}")
    user_req = Net::HTTP::Get.new(user_uri)
    user_req['Authorization'] = "Bearer #{ENV['SLACK_BOT_TOKEN']}"
    user_res = Net::HTTP.start(user_uri.hostname, user_uri.port, use_ssl: true) { |http| http.request(user_req) }
    user_data = JSON.parse(user_res.body)

    puts "DEBUG: User API call for #{user_id}: #{user_data.inspect}"

    if user_data['ok'] && user_data['user']
      real_name = user_data['user']['real_name'] || user_data['user']['display_name'] || user_data['user']['name'] || user_id
      user_names[user_id] = real_name
      puts "DEBUG: Mapped #{user_id} to #{real_name}"
    else
      user_names[user_id] = user_id
      puts "DEBUG: Failed to get user info for #{user_id}, using ID as fallback"
    end
  end

  # Add user names to messages
  messages.each do |message|
    if message['user'] && user_names[message['user']]
      message['user_name'] = user_names[message['user']]
      puts "DEBUG: Message from #{message['user']} assigned name: #{message['user_name']}"
    end
  end

  messages
end

def github_comment(issue_number, org, repo, body)
  uri = URI("https://api.github.com/repos/#{org}/#{repo}/issues/#{issue_number}/comments")
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "token #{ENV['GITHUB_TOKEN']}"
  req['Content-Type'] = 'application/json'
  req.body = { body: body }.to_json

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  unless res.code.to_i == 201
    puts "GitHub POST failed:"
    puts "URL: #{uri}"
    puts "Status: #{res.code} #{res.message}"
    puts "Body: #{res.body}"
    puts "Request: #{req.body}"
    halt 500, "GitHub error: #{res.body}"
  end

  # Parse the response to get the comment URL
  comment_data = JSON.parse(res.body)
  comment_url = comment_data['html_url']

  puts "DEBUG: Successfully posted to GitHub issue ##{issue_number}, comment URL: #{comment_url}"
  comment_url
end

def post_slack_reply(channel, thread_ts, comment_url)
  uri = URI("https://slack.com/api/chat.postMessage")
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "Bearer #{ENV['SLACK_BOT_TOKEN']}"
  req['Content-Type'] = 'application/json'

  message = {
    channel: channel,
    thread_ts: thread_ts,
    text: "✅ Thread posted to GitHub: #{comment_url}",
    unfurl_links: false,
    unfurl_media: false
  }

  req.body = message.to_json

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  response_data = JSON.parse(res.body)

  if response_data['ok']
    puts "DEBUG: Successfully posted Slack reply"
  else
    puts "DEBUG: Failed to post Slack reply: #{response_data['error']}"
  end
end
