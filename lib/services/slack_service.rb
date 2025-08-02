# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class SlackService
  API_BASE = 'https://slack.com/api'

  def initialize(token)
    @token = token
  end

  def get_thread_messages(channel, thread_ts)
    puts "DEBUG: Fetching messages for channel #{channel}, thread #{thread_ts}"
    response = api_request('conversations.replies', { channel: channel, ts: thread_ts })

    unless response['ok']
      puts "ERROR: Slack API failed: #{response['error']}"
      handle_api_error(response['error'], channel)
      return []
    end

    messages = response['messages'] || []
    puts "DEBUG: Found #{messages.length} messages in thread"

    return [] if messages.empty?

    enhance_messages_with_user_info(messages)
  end

  def join_channel(channel)
    puts "DEBUG: Attempting to join channel #{channel}"
    response = api_request('conversations.join', { channel: channel }, method: :post)

    if response['ok']
      puts "DEBUG: Successfully joined channel #{channel}"
      true
    else
      puts "DEBUG: Failed to join channel #{channel}: #{response['error']}"
      false
    end
  end

  def post_message(channel, thread_ts, text)
    puts "DEBUG: Posting reply to channel #{channel}, thread #{thread_ts}"

    message_data = {
      channel: channel,
      thread_ts: thread_ts,
      text: text,
      unfurl_links: false,
      unfurl_media: false,
    }

    response = api_request('chat.postMessage', message_data, method: :post)

    if response['ok']
      puts 'DEBUG: Successfully posted Slack reply'
      true
    else
      puts "DEBUG: Failed to post Slack reply: #{response['error']}"
      false
    end
  end

  def open_modal(trigger_id, view)
    response = api_request('views.open', { trigger_id: trigger_id, view: view }, method: :post)
    {
      success: response['ok'],
      status_code: response['ok'] ? 200 : 400,
      body: response['ok'] ? '' : response.to_json,
    }
  end

  def get_user_info(user_id)
    response = api_request('users.info', { user: user_id })

    if response['ok'] && response['user']
      user = response['user']
      real_name = user['real_name'] || user['display_name'] || user['name'] || user_id
      puts "DEBUG: Mapped #{user_id} to #{real_name}"
      real_name
    else
      puts "DEBUG: Failed to get user info for #{user_id}, using ID as fallback"
      user_id
    end
  end

  private

  def api_request(endpoint, params = {}, method: :get)
    uri = URI("#{API_BASE}/#{endpoint}")

    if method == :get
      uri.query = URI.encode_www_form(params) unless params.empty?
      req = Net::HTTP::Get.new(uri)
    else
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = params.to_json
    end

    req['Authorization'] = "Bearer #{@token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    JSON.parse(res.body)
  end

  def handle_api_error(error, channel)
    case error
    when 'not_in_channel'
      puts 'ERROR: Bot not in channel - attempting to join channel automatically'
      if join_channel(channel)
        puts 'DEBUG: Successfully joined channel, caller should retry'
      else
        puts 'ERROR: Failed to join channel automatically - user needs to add bot manually'
      end
    when 'missing_scope'
      puts 'ERROR: Missing OAuth scopes - needs channels:history and/or groups:history'
    when 'channel_not_found'
      puts 'ERROR: Channel not found - invalid channel ID'
    else
      puts "ERROR: Unknown error: #{error}"
    end
  end

  def enhance_messages_with_user_info(messages)
    # Get user info for all unique users in the thread
    user_ids = messages.map { |m| m['user'] }.compact.uniq

    # Extract user IDs from mentions in message text
    mentioned_user_ids = []
    messages.each do |message|
      text = message['text'] || ''
      mentions = text.scan(/<@([A-Z0-9]+)>/).flatten
      mentioned_user_ids.concat(mentions)
    end

    # Combine all user IDs and fetch user info
    all_user_ids = (user_ids + mentioned_user_ids).uniq
    user_names = {}

    all_user_ids.each do |user_id|
      user_names[user_id] = get_user_info(user_id)
    end

    # Add user names to messages
    messages.each do |message|
      if message['user'] && user_names[message['user']]
        message['user_name'] = user_names[message['user']]
        puts "DEBUG: Message from #{message['user']} assigned name: #{message['user_name']}"
      end

      # Add user mentions mapping to each message
      message['user_mentions'] = user_names
    end

    messages
  end
end
