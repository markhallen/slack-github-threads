# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'encryption'

module Config
  class ProjectConfig
    attr_reader :projects

    def initialize(config_path: '.config/projects.enc')
      @config_path = config_path
      @projects = []
    end

    def load!(passphrase)
      unless File.exist?(@config_path)
        @projects = []
        return self
      end

      encoded_blob = File.read(@config_path)
      yaml = Config::Encryption.decrypt(encoded_blob, passphrase)
      data = YAML.safe_load(yaml, permitted_classes: [Symbol]) || {}
      @projects = (data['projects'] || []).map { |p| normalize_project(p) }
      self
    end

    def save!(passphrase)
      dir = File.dirname(@config_path)
      FileUtils.mkdir_p(dir)

      data = { 'projects' => @projects.map { |p| stringify_project(p) } }
      yaml = YAML.dump(data)
      encoded_blob = Config::Encryption.encrypt(yaml, passphrase)
      File.write(@config_path, encoded_blob)
      self
    end

    def find_by_team_id(team_id)
      @projects.find { |p| p[:slack_team_id] == team_id }
    end

    def add_project(attrs)
      project = normalize_project(attrs)
      raise ArgumentError, 'Project name is required' if project[:name].to_s.strip.empty?
      raise ArgumentError, 'Slack team ID is required' if project[:slack_team_id].to_s.strip.empty?
      raise ArgumentError, "Project '#{project[:name]}' already exists" if find_by_name(project[:name])
      if find_by_team_id(project[:slack_team_id])
        raise ArgumentError, "Team ID '#{project[:slack_team_id]}' already in use"
      end

      @projects << project
      project
    end

    def update_project(name, attrs)
      project = find_by_name(name)
      raise ArgumentError, "Project '#{name}' not found" unless project

      attrs.each do |key, value|
        sym_key = key.to_sym
        project[sym_key] = value if project.key?(sym_key)
      end

      validate_project!(project)
      project
    end

    def remove_project(name)
      project = find_by_name(name)
      raise ArgumentError, "Project '#{name}' not found" unless project

      @projects.delete(project)
      project
    end

    def find_by_name(name)
      @projects.find { |p| p[:name] == name }
    end

    def empty?
      @projects.empty?
    end

    private

    def validate_project!(project)
      raise ArgumentError, 'Project name is required' if project[:name].to_s.strip.empty?
      raise ArgumentError, 'Slack team ID is required' if project[:slack_team_id].to_s.strip.empty?

      duplicate = @projects.find { |p| p[:slack_team_id] == project[:slack_team_id] && p != project }
      raise ArgumentError, "Team ID '#{project[:slack_team_id]}' already in use" if duplicate
    end

    def normalize_project(attrs)
      {
        name: attrs[:name] || attrs['name'],
        slack_team_id: attrs[:slack_team_id] || attrs['slack_team_id'],
        slack_bot_token: attrs[:slack_bot_token] || attrs['slack_bot_token'],
        github_token: attrs[:github_token] || attrs['github_token'],
        default_github_org: attrs[:default_github_org] || attrs['default_github_org'],
      }
    end

    def stringify_project(project)
      project.transform_keys(&:to_s)
    end
  end
end
