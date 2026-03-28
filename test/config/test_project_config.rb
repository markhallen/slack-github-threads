# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/config/project_config'
require 'tmpdir'

class TestProjectConfig < Minitest::Spec
  let(:passphrase) { 'test-passphrase' }
  let(:tmpdir) { Dir.mktmpdir }
  let(:config_path) { File.join(tmpdir, 'projects.enc') }
  let(:config) { Config::ProjectConfig.new(config_path: config_path) }

  let(:sample_project) do
    {
      name: 'My Company',
      slack_team_id: 'T12345',
      slack_bot_token: 'xoxb-test-token',
      github_token: 'ghp_testtoken123',
      default_github_org: 'mycompany',
    }
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#load!' do
    it 'returns empty projects when file does not exist' do
      config.load!(passphrase)

      assert_empty config
      assert_empty config.projects
    end

    it 'loads projects from encrypted file' do
      config.add_project(sample_project)
      config.save!(passphrase)

      loaded = Config::ProjectConfig.new(config_path: config_path)
      loaded.load!(passphrase)

      refute_empty loaded
      assert_equal 1, loaded.projects.length
      assert_equal 'My Company', loaded.projects.first[:name]
    end

    it 'raises DecryptionError with wrong passphrase' do
      config.add_project(sample_project)
      config.save!(passphrase)

      loaded = Config::ProjectConfig.new(config_path: config_path)
      assert_raises(Config::Encryption::DecryptionError) do
        loaded.load!('wrong-passphrase')
      end
    end
  end

  describe '#save!' do
    it 'creates the config directory if it does not exist' do
      nested_path = File.join(tmpdir, 'nested', 'dir', 'projects.enc')
      nested_config = Config::ProjectConfig.new(config_path: nested_path)
      nested_config.add_project(sample_project)
      nested_config.save!(passphrase)

      assert_path_exists nested_path
    end

    it 'writes an encrypted file that is not readable as plain YAML' do
      config.add_project(sample_project)
      config.save!(passphrase)

      raw = File.read(config_path)
      parsed = YAML.safe_load(raw) rescue nil # rubocop:disable Style/RescueModifier

      refute_kind_of Hash, parsed
    end
  end

  describe '#add_project' do
    it 'adds a project to the list' do
      config.add_project(sample_project)

      assert_equal 1, config.projects.length
      assert_equal 'My Company', config.projects.first[:name]
    end

    it 'raises ArgumentError for missing name' do
      assert_raises(ArgumentError) do
        config.add_project(sample_project.merge(name: ''))
      end
    end

    it 'raises ArgumentError for missing team ID' do
      assert_raises(ArgumentError) do
        config.add_project(sample_project.merge(slack_team_id: ''))
      end
    end

    it 'raises ArgumentError for duplicate name' do
      config.add_project(sample_project)
      assert_raises(ArgumentError) do
        config.add_project(sample_project)
      end
    end

    it 'normalizes string keys to symbols' do
      string_attrs = {
        'name' => 'String Project',
        'slack_team_id' => 'T99999',
        'slack_bot_token' => 'xoxb-string',
        'github_token' => 'ghp_string',
        'default_github_org' => 'stringorg',
      }
      config.add_project(string_attrs)
      project = config.projects.first

      assert_equal 'String Project', project[:name]
      assert_equal 'T99999', project[:slack_team_id]
    end
  end

  describe '#update_project' do
    it 'updates project attributes' do
      config.add_project(sample_project)
      config.update_project('My Company', github_token: 'ghp_newtoken')

      assert_equal 'ghp_newtoken', config.projects.first[:github_token]
    end

    it 'raises ArgumentError for unknown project' do
      assert_raises(ArgumentError) do
        config.update_project('Nonexistent', github_token: 'ghp_new')
      end
    end
  end

  describe '#remove_project' do
    it 'removes a project by name' do
      config.add_project(sample_project)
      config.remove_project('My Company')

      assert_empty config
    end

    it 'raises ArgumentError for unknown project' do
      assert_raises(ArgumentError) do
        config.remove_project('Nonexistent')
      end
    end
  end

  describe '#find_by_team_id' do
    it 'returns the matching project' do
      config.add_project(sample_project)
      project = config.find_by_team_id('T12345')

      assert_equal 'My Company', project[:name]
    end

    it 'returns nil for unknown team ID' do
      config.add_project(sample_project)

      assert_nil config.find_by_team_id('T99999')
    end
  end

  describe 'round-trip with multiple projects' do
    it 'persists and reloads multiple projects' do
      config.add_project(sample_project)
      config.add_project(
        name: 'Side Project',
        slack_team_id: 'T67890',
        slack_bot_token: 'xoxb-side-token',
        github_token: 'ghp_sidetoken',
        default_github_org: nil
      )
      config.save!(passphrase)

      loaded = Config::ProjectConfig.new(config_path: config_path)
      loaded.load!(passphrase)

      assert_equal 2, loaded.projects.length
      assert_equal 'Side Project', loaded.find_by_team_id('T67890')[:name]
      assert_nil loaded.find_by_team_id('T67890')[:default_github_org]
    end
  end
end
