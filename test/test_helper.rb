# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/spec'
require 'rack/test'
require 'webmock/minitest'
require 'json'

# Load environment for testing
ENV['RACK_ENV'] = 'test'
ENV['SLACK_BOT_TOKEN'] = 'xoxb-test-token'
ENV['GITHUB_TOKEN'] = 'ghp_test_token'
ENV['DEBUG'] = 'false' # Disable debug logging in tests

# Load the application
require_relative '../app'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

module Minitest
  class Test
    include Rack::Test::Methods

    def app
      Sinatra::Application
    end

    def setup
      WebMock.reset!
    end

    # Helper methods for creating test data
    def slack_message(user_id = 'U123', text = 'Test message', user_name = 'Test User')
      {
        'user' => user_id,
        'text' => text,
        'user_name' => user_name,
        'user_mentions' => { user_id => user_name },
      }
    end

    def slack_thread_response(messages = [slack_message])
      {
        'ok' => true,
        'messages' => messages,
      }
    end

    def slack_user_response(user_id = 'U123', real_name = 'Test User')
      {
        'ok' => true,
        'user' => {
          'id' => user_id,
          'real_name' => real_name,
          'name' => real_name.downcase.gsub(' ', '.'),
        },
      }
    end

    def github_comment_response(url = 'https://github.com/org/repo/issues/1#issuecomment-123')
      {
        'html_url' => url,
        'id' => 123,
      }
    end

    def stub_slack_conversations_replies(channel = 'C123', messages = [slack_message])
      stub_request(:get, 'https://slack.com/api/conversations.replies')
        .with(query: hash_including(channel: channel))
        .to_return(
          status: 200,
          body: slack_thread_response(messages).to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def stub_slack_users_info(user_id = 'U123', real_name = 'Test User')
      stub_request(:get, 'https://slack.com/api/users.info')
        .with(query: { user: user_id })
        .to_return(
          status: 200,
          body: slack_user_response(user_id, real_name).to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def stub_slack_chat_post_message
      stub_request(:post, 'https://slack.com/api/chat.postMessage')
        .to_return(
          status: 200,
          body: { 'ok' => true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def stub_github_create_comment(org = 'owner', repo = 'repo', issue = '1')
      stub_request(:post, "https://api.github.com/repos/#{org}/#{repo}/issues/#{issue}/comments")
        .to_return(
          status: 201,
          body: github_comment_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def slack_modal_payload(type, callback_id, values = {})
      {
        type: 'view_submission',
        view: {
          callback_id: callback_id,
          state: {
            values: values,
          },
          private_metadata: if type == 'message'
                              JSON.generate({ channel_id: 'C123',
                                              thread_ts: '1234567890.123456', })
                            else
                              '{}'
                            end,
        },
      }
    end
  end
end
