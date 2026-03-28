# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/cli/tui'
require 'tmpdir'

class TestTui < Minitest::Spec
  let(:tmpdir) { Dir.mktmpdir }
  let(:config_path) { File.join(tmpdir, 'projects.enc') }
  let(:passphrase) { 'test-passphrase' }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  def build_tui(prompt)
    CLI::Tui.new(config_path: config_path, prompt: prompt)
  end

  describe 'add_project flow' do
    it 'adds a project and saves to encrypted file' do
      prompt = MockPrompt.new
      prompt.queue_mask(passphrase)        # choose passphrase
      prompt.queue_mask(passphrase)        # confirm passphrase

      # Main menu: Add project, then Exit
      prompt.queue_select(:add_project)
      prompt.queue_ask('My Company')       # name
      prompt.queue_ask('T12345')           # team_id
      prompt.queue_mask('xoxb-test-token') # slack token
      prompt.queue_mask('ghp_testtoken')   # github token
      prompt.queue_ask('mycompany')        # default org

      prompt.queue_select(:exit)           # exit

      tui = build_tui(prompt)
      tui.run

      # Verify the config was saved
      config = Config::ProjectConfig.new(config_path: config_path)
      config.load!(passphrase)

      assert_equal 1, config.projects.length
      assert_equal 'My Company', config.projects.first[:name]
      assert_equal 'T12345', config.projects.first[:slack_team_id]
    end
  end

  describe 'remove_project flow' do
    it 'removes a project' do
      # Pre-populate config
      config = Config::ProjectConfig.new(config_path: config_path)
      config.add_project(
        name: 'To Remove',
        slack_team_id: 'T99999',
        slack_bot_token: 'xoxb-remove',
        github_token: 'ghp_remove'
      )
      config.save!(passphrase)

      prompt = MockPrompt.new
      prompt.queue_mask(passphrase)        # enter passphrase

      prompt.queue_select(:remove_project) # main menu
      prompt.queue_select('To Remove')     # select project
      prompt.queue_yes(true)               # confirm removal
      prompt.queue_select(:exit)           # exit

      tui = build_tui(prompt)
      tui.run

      # Verify removal
      reloaded = Config::ProjectConfig.new(config_path: config_path)
      reloaded.load!(passphrase)

      assert_empty reloaded
    end
  end

  describe 'list_projects flow' do
    it 'lists projects without error' do
      config = Config::ProjectConfig.new(config_path: config_path)
      config.add_project(
        name: 'Listed Project',
        slack_team_id: 'T11111',
        slack_bot_token: 'xoxb-listed',
        github_token: 'ghp_listed',
        default_github_org: 'listedorg'
      )
      config.save!(passphrase)

      prompt = MockPrompt.new
      prompt.queue_mask(passphrase)

      prompt.queue_select(:list_projects)
      prompt.queue_select(:exit)

      tui = build_tui(prompt)
      output = capture_io { tui.run }

      assert_includes output.first, 'Listed Project'
    end
  end
end

# Minimal mock for TTY::Prompt that replays queued responses
class MockPrompt
  def initialize
    @mask_queue = []
    @ask_queue = []
    @select_queue = []
    @yes_queue = []
    @messages = []
  end

  def queue_mask(value)
    @mask_queue << value
  end

  def queue_ask(value)
    @ask_queue << value
  end

  def queue_select(value)
    @select_queue << value
  end

  def queue_yes(value)
    @yes_queue << value
  end

  def mask(_message, **_opts)
    @mask_queue.shift
  end

  def ask(_message, **_opts)
    @ask_queue.shift
  end

  def select(_message, choices, **_opts)
    selected_value = @select_queue.shift
    # If choices are hashes with :value keys, find the matching one
    if choices.is_a?(Array) && choices.first.is_a?(Hash)
      match = choices.find { |c| c[:value] == selected_value }
      return match[:value] if match
    end
    selected_value
  end

  def yes?(_message, **_opts)
    @yes_queue.shift
  end

  def ok(message)
    @messages << [:ok, message]
  end

  def warn(message)
    @messages << [:warn, message]
  end

  def error(message)
    @messages << [:error, message]
  end
end
