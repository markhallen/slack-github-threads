require_relative 'test_helper'

class AppTest < Minitest::Test
  def test_health_check
    get '/up'
    
    assert last_response.ok?
    assert_equal 'OK', last_response.body
  end

  def test_ghcomment_success
    stub_slack_conversations_replies('C123', [slack_message('U123', 'Hello world', 'John Doe')])
    stub_slack_users_info('U123', 'John Doe')
    stub_slack_chat_post_message
    stub_github_create_comment('owner', 'repo', '1')

    post '/ghcomment', {
      text: 'https://github.com/owner/repo/issues/1',
      channel_id: 'C123',
      thread_ts: '1234567890.123456'
    }

    assert last_response.ok?
    assert_includes last_response.body, '✅ Posted to GitHub'
  end

  def test_ghcomment_missing_thread
    post '/ghcomment', {
      text: 'https://github.com/owner/repo/issues/1',
      channel_id: 'C123'
    }

    assert_equal 400, last_response.status
    assert_equal 'Missing thread.', last_response.body
  end

  def test_ghcomment_missing_issue_url
    post '/ghcomment', {
      channel_id: 'C123',
      thread_ts: '1234567890.123456'
    }

    assert_equal 400, last_response.status
    assert_equal 'Missing issue URL.', last_response.body
  end

  def test_global_shortcut
    # Stub modal opening
    stub_request(:post, "https://slack.com/api/views.open")
      .to_return(
        status: 200,
        body: { 'ok' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    payload = {
      type: 'shortcut',
      trigger_id: 'trigger123'
    }

    post '/shortcut', { payload: payload.to_json }

    assert last_response.ok?
  end

  def test_message_shortcut
    # Stub modal opening
    stub_request(:post, "https://slack.com/api/views.open")
      .to_return(
        status: 200,
        body: { 'ok' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    payload = {
      type: 'message_action',
      trigger_id: 'trigger123',
      channel: { id: 'C123' },
      message: { ts: '1234567890.123456' }
    }

    post '/shortcut', { payload: payload.to_json }

    assert last_response.ok?
    assert_empty last_response.body
  end

  def test_global_modal_submission_success
    stub_slack_conversations_replies('C123', [slack_message('U123', 'Hello world', 'John Doe')])
    stub_slack_users_info('U123', 'John Doe')
    stub_slack_chat_post_message
    stub_github_create_comment('owner', 'repo', '1')

    payload = slack_modal_payload('global', 'gh_comment_modal_global', {
      thread_block: {
        thread_url: {
          value: 'https://example.slack.com/archives/C123/p1234567890123456'
        }
      },
      issue_block: {
        issue_url: {
          value: 'https://github.com/owner/repo/issues/1'
        }
      }
    })

    post '/shortcut', { payload: payload.to_json }

    assert last_response.ok?
    assert_empty last_response.body
  end

  def test_global_modal_submission_invalid_slack_url
    payload = slack_modal_payload('global', 'gh_comment_modal_global', {
      thread_block: {
        thread_url: {
          value: 'not-a-slack-url'
        }
      },
      issue_block: {
        issue_url: {
          value: 'https://github.com/owner/repo/issues/1'
        }
      }
    })

    post '/shortcut', { payload: payload.to_json }

    assert last_response.ok?
    response_data = JSON.parse(last_response.body)
    assert_equal 'errors', response_data['response_action']
    assert_includes response_data['errors']['thread_block'], 'Invalid Slack URL format'
  end

  def test_message_modal_submission_success
    stub_slack_conversations_replies('C123', [slack_message('U123', 'Hello world', 'John Doe')])
    stub_slack_users_info('U123', 'John Doe')
    stub_slack_chat_post_message
    stub_github_create_comment('owner', 'repo', '1')

    payload = slack_modal_payload('message', 'gh_comment_modal_message', {
      issue_block: {
        issue_url: {
          value: 'https://github.com/owner/repo/issues/1'
        }
      }
    })

    post '/shortcut', { payload: payload.to_json }

    assert last_response.ok?
    assert_empty last_response.body
  end

  def test_modal_submission_invalid_github_url
    payload = slack_modal_payload('message', 'gh_comment_modal_message', {
      issue_block: {
        issue_url: {
          value: 'not-a-github-url'
        }
      }
    })

    post '/shortcut', { payload: payload.to_json }

    assert last_response.ok?
    response_data = JSON.parse(last_response.body)
    assert_equal 'errors', response_data['response_action']
    assert_includes response_data['errors']['issue_block'], 'Invalid GitHub issue URL'
  end

  def test_unsupported_payload_type
    payload = { type: 'unknown' }

    post '/shortcut', { payload: payload.to_json }

    assert_equal 400, last_response.status
    assert_includes last_response.body, 'Unsupported payload type'
  end

  def test_missing_environment_variables
    # Temporarily unset environment variables
    old_slack_token = ENV['SLACK_BOT_TOKEN']
    old_github_token = ENV['GITHUB_TOKEN']
    
    ENV.delete('SLACK_BOT_TOKEN')
    ENV.delete('GITHUB_TOKEN')

    post '/ghcomment', {
      text: 'https://github.com/owner/repo/issues/1',
      channel_id: 'C123',
      thread_ts: '1234567890.123456'
    }

    assert_equal 500, last_response.status
    assert_includes last_response.body, 'Missing environment variables'

    # Restore environment variables
    ENV['SLACK_BOT_TOKEN'] = old_slack_token
    ENV['GITHUB_TOKEN'] = old_github_token
  end
end
