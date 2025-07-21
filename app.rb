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
  thread_text = messages.map { |m| "*#{m['user'] || 'unknown'}*: #{m['text']}" }.join("\n\n")

  if issue_url =~ %r{github\.com/([^/]+)/([^/]+)/issues/(\d+)}
    org, repo, issue_number = $1, $2, $3
  else
    halt 400, "Invalid GitHub issue URL."
  end

  github_comment(issue_number, org, repo, thread_text)
end

post '/shortcut' do
  request.body.rewind
  raw_payload = request.body.read
  parsed = URI.decode_www_form(raw_payload).to_h
  payload = JSON.parse(parsed['payload'])

  if payload['type'] == 'shortcut'
    # Open a modal to collect GitHub issue URL
    trigger_id = payload['trigger_id']
    view = {
      type: "modal",
      callback_id: "gh_comment_modal",
      title: { type: "plain_text", text: "Post Thread to GitHub" },
      submit: { type: "plain_text", text: "Post" },
      close: { type: "plain_text", text: "Cancel" },
      private_metadata: JSON.generate({
        channel_id: payload.dig('channel', 'id'),
        message_ts: payload.dig('message', 'ts'),
        thread_ts: payload.dig('message', 'thread_ts') || payload.dig('message', 'ts')
      }),
      blocks: [
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

    unless issue_url =~ %r{github\.com/([^/]+)/([^/]+)/issues/(\d+)}
      status 200
      return json(response_action: 'errors', errors: { issue_block: 'Invalid GitHub issue URL.' })
    end

    org, repo, issue_number = $1, $2, $3

    messages = get_thread_messages(channel_id, thread_ts)
    thread_text = messages.map { |m| "*#{m['user'] || 'unknown'}*: #{m['text']}" }.join("\n\n")
    
    puts "DEBUG: Channel: #{channel_id}, Thread: #{thread_ts}, Messages: #{messages.length}, Text: '#{thread_text[0..100]}'"

    github_comment(issue_number, org, repo, thread_text)
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
  JSON.parse(res.body)['messages'] || []
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

  "Posted thread to GitHub issue ##{issue_number}"
end
