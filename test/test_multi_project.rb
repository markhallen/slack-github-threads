# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/config/project_config'
require 'tmpdir'

class MultiProjectTest < Minitest::Test
  def setup
    super
    @tmpdir = Dir.mktmpdir
    @config_path = File.join(@tmpdir, 'projects.enc')
    @passphrase = 'test-passphrase'

    # Create a project config with a test project
    config = Config::ProjectConfig.new(config_path: @config_path)
    config.add_project(
      name: 'Test Workspace',
      slack_team_id: 'T_MULTI',
      slack_bot_token: 'xoxb-multi-project-token',
      github_token: 'ghp_multi_project_token',
      default_github_org: 'testorg'
    )
    config.save!(@passphrase)

    # Load config into the app
    loaded = Config::ProjectConfig.new(config_path: @config_path)
    loaded.load!(@passphrase)
    Sinatra::Application.set :project_config, loaded
  end

  def teardown
    # Restore to no project config
    Sinatra::Application.set :project_config, nil
    FileUtils.rm_rf(@tmpdir)
  end

  def test_ghcomment_uses_project_tokens_for_matching_team_id
    # Stub using multi-project tokens (the Authorization header will contain the project's token)
    slack_stub = stub_request(:get, 'https://slack.com/api/conversations.replies')
      .with(
        query: hash_including(channel: 'C123'),
        headers: { 'Authorization' => 'Bearer xoxb-multi-project-token' }
      )
      .to_return(
        status: 200,
        body: slack_thread_response([slack_message]).to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_slack_users_info
    stub_slack_chat_post_message

    github_stub = stub_request(:post, 'https://api.github.com/repos/owner/repo/issues/1/comments')
      .with(headers: { 'Authorization' => 'token ghp_multi_project_token' })
      .to_return(
        status: 201,
        body: github_comment_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    post '/ghcomment', {
      text: 'https://github.com/owner/repo/issues/1',
      channel_id: 'C123',
      thread_ts: '1234567890.123456',
      team_id: 'T_MULTI',
    }

    assert_predicate last_response, :ok?
    assert_requested slack_stub
    assert_requested github_stub
  end

  def test_ghcomment_falls_back_to_env_vars_for_unknown_team_id
    stub_slack_conversations_replies('C123', [slack_message])
    stub_slack_users_info
    stub_slack_chat_post_message
    stub_github_create_comment('owner', 'repo', '1')

    post '/ghcomment', {
      text: 'https://github.com/owner/repo/issues/1',
      channel_id: 'C123',
      thread_ts: '1234567890.123456',
      team_id: 'T_UNKNOWN',
    }

    assert_predicate last_response, :ok?
  end

  def test_ghcomment_falls_back_to_env_vars_when_no_team_id
    stub_slack_conversations_replies('C123', [slack_message])
    stub_slack_users_info
    stub_slack_chat_post_message
    stub_github_create_comment('owner', 'repo', '1')

    post '/ghcomment', {
      text: 'https://github.com/owner/repo/issues/1',
      channel_id: 'C123',
      thread_ts: '1234567890.123456',
    }

    assert_predicate last_response, :ok?
  end

  def test_shortcut_uses_project_tokens_for_matching_team_id
    views_stub = stub_request(:post, 'https://slack.com/api/views.open')
      .with(headers: { 'Authorization' => 'Bearer xoxb-multi-project-token' })
      .to_return(
        status: 200,
        body: { 'ok' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    payload = {
      type: 'shortcut',
      trigger_id: 'trigger123',
      team: { id: 'T_MULTI' },
    }

    post '/shortcut', { payload: payload.to_json }

    assert_predicate last_response, :ok?
    assert_requested views_stub
  end
end
