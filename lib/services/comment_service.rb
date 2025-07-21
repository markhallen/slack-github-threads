require_relative 'slack_service'
require_relative 'github_service'
require_relative 'text_processor'
require_relative '../helpers/modal_builder'

class CommentService
  def initialize(slack_token, github_token)
    @slack = SlackService.new(slack_token)
    @github = GitHubService.new(github_token)
  end

  def post_thread_to_github(channel_id, thread_ts, issue_url)
    # Parse GitHub issue URL
    github_info = GitHubService.parse_issue_url(issue_url)
    raise "Invalid GitHub issue URL" unless github_info

    # Get messages from Slack thread
    messages = @slack.get_thread_messages(channel_id, thread_ts)
    
    # Handle retry for channel joining
    if messages.empty?
      # Try once more in case we just joined the channel
      sleep(1) # Give Slack a moment to update permissions
      messages = @slack.get_thread_messages(channel_id, thread_ts)
    end

    raise "No messages found in thread" if messages.empty?

    # Process messages into formatted text
    thread_text = TextProcessor.process_messages(messages)
    
    puts "DEBUG: Messages: #{messages.length}, Text preview: '#{thread_text[0..100]}'"

    # Post to GitHub
    comment_url = @github.create_comment(
      github_info[:org], 
      github_info[:repo], 
      github_info[:issue_number], 
      thread_text
    )

    # Post reply to Slack thread
    @slack.post_message(
      channel_id, 
      thread_ts, 
      "✅ Thread posted to GitHub: #{comment_url}"
    )

    comment_url
  end

  def open_global_shortcut_modal(trigger_id)
    view = ModalBuilder.global_shortcut_modal
    @slack.open_modal(trigger_id, view)
  end

  def open_message_shortcut_modal(trigger_id, channel_id, thread_ts)
    view = ModalBuilder.message_shortcut_modal(channel_id, thread_ts)
    @slack.open_modal(trigger_id, view)
  end
end
