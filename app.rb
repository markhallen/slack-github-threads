# frozen_string_literal: true

require 'sinatra'
require 'json'
require 'logger'
require 'fileutils'
require 'dotenv/load'

# Load our services
require_relative 'lib/services/comment_service'
require_relative 'lib/services/text_processor'
require_relative 'lib/helpers/modal_builder'

# Configuration
configure do
  set :environment, ENV.fetch('RACK_ENV', 'development')
  set :port, ENV.fetch('PORT', 3000)

  # Enable debug mode in development or when explicitly set
  set :debug_mode, ENV.fetch('DEBUG', nil) == 'true' || development?

  # Setup logging
  log_dir = File.join(settings.root, 'log')
  FileUtils.mkdir_p(log_dir)

  log_file = File.join(log_dir, "#{settings.environment}.log")
  log_device = settings.environment == 'test' ? StringIO.new : log_file

  set :logger, Logger.new(log_device, level: settings.debug_mode ? Logger::DEBUG : Logger::INFO)

  # Configure Sinatra's built-in logging
  set :logging, true
  set :dump_errors, settings.debug_mode

  # Add startup logging (only in debug mode)
  if settings.debug_mode
    puts 'Starting slack-github-threads app...'
    puts "RACK_ENV: #{ENV.fetch('RACK_ENV', nil)}"
    puts "PORT: #{ENV.fetch('PORT', nil)}"
    puts "Environment variables loaded: #{ENV.keys.grep(/GITHUB|SLACK/).join(', ')}"
    puts "Log file: #{log_file}"
  end

  # Log startup
  settings.logger.info "Starting slack-github-threads app (#{settings.environment})"
end

# Helpers
helpers do
  def json(response_hash)
    content_type :json
    response_hash.to_json
  end

  def debug_log(message)
    puts message if settings.debug_mode
    logger.debug(message)
  end

  def info_log(message)
    logger.info(message)
  end

  def error_log(message)
    puts "ERROR: #{message}"
    logger.error(message)
  end

  def comment_service
    @comment_service ||= CommentService.new(
      ENV.fetch('SLACK_BOT_TOKEN', nil),
      ENV.fetch('GITHUB_TOKEN', nil),
      debug: settings.debug_mode,
      logger: logger
    )
  end

  def validate_environment!
    missing = []
    missing << 'SLACK_BOT_TOKEN' unless ENV['SLACK_BOT_TOKEN']
    missing << 'GITHUB_TOKEN' unless ENV['GITHUB_TOKEN']

    return if missing.empty?

    halt 500, "Missing environment variables: #{missing.join(', ')}"
  end
end

# Health check endpoint
get '/up' do
  status 200
  'OK'
end

# Slack slash command endpoint
post '/ghcomment' do
  validate_environment!

  issue_url = params['text']&.strip
  channel_id = params['channel_id']
  thread_ts = params['thread_ts'] || params['message_ts']

  halt 400, 'Missing thread.' unless thread_ts
  halt 400, 'Missing issue URL.' unless issue_url && !issue_url.empty?

  begin
    comment_url = comment_service.post_thread_to_github(channel_id, thread_ts, issue_url)
    info_log "Successfully posted comment to GitHub: #{comment_url}"
    status 200
    "✅ Posted to GitHub: #{comment_url}"
  rescue StandardError => e
    error_log "Failed to post comment: #{e.message}"
    error_log e.backtrace.join("\n")
    halt 500, "Failed to post comment: #{e.message}"
  end
end

# Slack shortcuts and modal submissions
post '/shortcut' do
  validate_environment!

  request.body.rewind
  raw_payload = request.body.read
  parsed = URI.decode_www_form(raw_payload).to_h
  payload = JSON.parse(parsed['payload'])

  case payload['type']
  when 'shortcut'
    handle_global_shortcut(payload)
  when 'message_action'
    handle_message_shortcut(payload)
  when 'view_submission'
    handle_modal_submission(payload)
  else
    halt 400, "Unsupported payload type: #{payload['type']}"
  end
end

def handle_global_shortcut(payload)
  trigger_id = payload['trigger_id']
  debug_log 'DEBUG: Global shortcut triggered'

  result = comment_service.open_global_shortcut_modal(trigger_id)

  status result[:status_code]
  body result[:body]
end

def handle_message_shortcut(payload)
  trigger_id = payload['trigger_id']
  channel_id = payload.dig('channel', 'id')
  message_ts = payload.dig('message', 'ts')
  thread_ts = payload.dig('message', 'thread_ts') || message_ts

  debug_log "DEBUG: Message shortcut - Channel: #{channel_id}, Thread: #{thread_ts}"

  result = comment_service.open_message_shortcut_modal(trigger_id, channel_id, thread_ts)

  # For message shortcuts, return empty response if modal opened successfully
  if result[:success]
    status 200
    body ''
  else
    status result[:status_code]
    body result[:body]
  end
end

def handle_modal_submission(payload)
  callback_id = payload.dig('view', 'callback_id')

  case callback_id
  when 'gh_comment_modal_global'
    handle_global_modal_submission(payload)
  when 'gh_comment_modal_message'
    handle_message_modal_submission(payload)
  else
    halt 400, "Unknown callback ID: #{callback_id}"
  end
end

def handle_global_modal_submission(payload)
  thread_url = payload.dig('view', 'state', 'values', 'thread_block', 'thread_url', 'value')
  issue_url = payload.dig('view', 'state', 'values', 'issue_block', 'issue_url', 'value')

  debug_log "DEBUG: Global shortcut submission - Thread URL: #{thread_url}, Issue URL: #{issue_url}"

  # Parse Slack thread URL
  thread_info = TextProcessor.parse_slack_thread_url(thread_url)
  unless thread_info
    status 200
    return json(response_action: 'errors', errors: {
                  thread_block: 'Invalid Slack URL format. Please copy the link from a message in the thread.',
                })
  end

  process_modal_submission(thread_info[:channel_id], thread_info[:thread_ts], issue_url)
end

def handle_message_modal_submission(payload)
  metadata = JSON.parse(payload.dig('view', 'private_metadata'))
  channel_id = metadata['channel_id']
  thread_ts = metadata['thread_ts']
  issue_url = payload.dig('view', 'state', 'values', 'issue_block', 'issue_url', 'value')

  debug_log "DEBUG: Message shortcut submission - Channel: #{channel_id}, Thread: #{thread_ts}, Issue: #{issue_url}"

  process_modal_submission(channel_id, thread_ts, issue_url)
end

def process_modal_submission(channel_id, thread_ts, issue_url)
  # Validate GitHub issue URL
  unless GitHubService.parse_issue_url(issue_url)
    status 200
    return json(response_action: 'errors', errors: {
                  issue_block: 'Invalid GitHub issue URL.',
                })
  end

  begin
    comment_service.post_thread_to_github(channel_id, thread_ts, issue_url)
    info_log "Successfully posted comment via modal to GitHub issue: #{issue_url}"
    status 200
    body '' # Required response for modals
  rescue StandardError => e
    error_log "Failed to post comment via modal: #{e.message}"
    status 200
    json(response_action: 'errors', errors: {
           issue_block: "Failed to post comment: #{e.message}",
         })
  end
end
