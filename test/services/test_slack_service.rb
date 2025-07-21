require_relative '../test_helper'
require_relative '../../lib/services/slack_service'

class SlackServiceTest < Minitest::Test
  def setup
    super
    @service = SlackService.new('test-token')
  end

  def test_get_thread_messages_success
    messages = [slack_message('U123', 'Hello world', 'John Doe')]
    
    # Stub conversations.replies
    stub_request(:get, "https://slack.com/api/conversations.replies")
      .with(query: { channel: 'C123', ts: '1234567890.123456' })
      .to_return(
        status: 200,
        body: slack_thread_response(messages).to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub users.info
    stub_slack_users_info('U123', 'John Doe')

    result = @service.get_thread_messages('C123', '1234567890.123456')
    
    assert_equal 1, result.length
    assert_equal 'Hello world', result[0]['text']
    assert_equal 'John Doe', result[0]['user_name']
  end

  def test_get_thread_messages_with_mentions
    messages = [slack_message('U123', 'Hello <@U456>', 'John Doe')]
    
    stub_request(:get, "https://slack.com/api/conversations.replies")
      .with(query: { channel: 'C123', ts: '1234567890.123456' })
      .to_return(
        status: 200,
        body: slack_thread_response(messages).to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub users.info for both users
    stub_slack_users_info('U123', 'John Doe')
    stub_slack_users_info('U456', 'Jane Smith')

    result = @service.get_thread_messages('C123', '1234567890.123456')
    
    assert_equal 1, result.length
    assert_includes result[0]['user_mentions'], 'U456'
    assert_equal 'Jane Smith', result[0]['user_mentions']['U456']
  end

  def test_get_thread_messages_not_in_channel
    # First request fails
    stub_request(:get, "https://slack.com/api/conversations.replies")
      .with(query: hash_including(channel: 'C123'))
      .to_return(
        status: 200,
        body: { 'ok' => false, 'error' => 'not_in_channel' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub successful join
    stub_request(:post, "https://slack.com/api/conversations.join")
      .to_return(
        status: 200,
        body: { 'ok' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.get_thread_messages('C123', '1234567890.123456')
    
    assert_empty result
  end

  def test_join_channel_success
    stub_request(:post, "https://slack.com/api/conversations.join")
      .with(body: { channel: 'C123' }.to_json)
      .to_return(
        status: 200,
        body: { 'ok' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.join_channel('C123')
    assert result
  end

  def test_join_channel_failure
    stub_request(:post, "https://slack.com/api/conversations.join")
      .to_return(
        status: 200,
        body: { 'ok' => false, 'error' => 'already_in_channel' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.join_channel('C123')
    refute result
  end

  def test_post_message_success
    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .with(body: {
        channel: 'C123',
        thread_ts: '1234567890.123456',
        text: 'Test message',
        unfurl_links: false,
        unfurl_media: false
      }.to_json)
      .to_return(
        status: 200,
        body: { 'ok' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.post_message('C123', '1234567890.123456', 'Test message')
    assert result
  end

  def test_get_user_info_success
    stub_slack_users_info('U123', 'John Doe')

    result = @service.get_user_info('U123')
    assert_equal 'John Doe', result
  end

  def test_get_user_info_fallback
    stub_request(:get, "https://slack.com/api/users.info")
      .with(query: { user: 'U123' })
      .to_return(
        status: 200,
        body: { 'ok' => false, 'error' => 'user_not_found' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.get_user_info('U123')
    assert_equal 'U123', result
  end
end
