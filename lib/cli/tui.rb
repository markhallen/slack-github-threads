# frozen_string_literal: true

require 'tty-prompt'
require 'tty-table'
require 'tty-screen'
require_relative '../config/project_config'

module CLI
  class Tui
    def initialize(config_path: '.config/projects.enc', prompt: TTY::Prompt.new)
      @config_path = config_path
      @prompt = prompt
      @config = Config::ProjectConfig.new(config_path: config_path)
      @passphrase = nil
    end

    def run
      @passphrase = prompt_passphrase
      @config.load!(@passphrase)
      main_menu_loop
      @prompt.warn('Restart the running app for config changes to take effect.') unless @config.empty?
    rescue Config::Encryption::DecryptionError
      @prompt.error('Wrong passphrase. Unable to decrypt config file.')
      exit 1
    end

    private

    def prompt_passphrase
      if File.exist?(@config_path)
        @prompt.mask('Enter config passphrase:', required: true)
      else
        @prompt.ok('No config file found. Creating a new one.')
        passphrase = @prompt.mask('Choose a passphrase for encrypting your config:', required: true)
        confirm = @prompt.mask('Confirm passphrase:', required: true)
        unless passphrase == confirm
          @prompt.error('Passphrases do not match.')
          exit 1
        end
        passphrase
      end
    end

    def main_menu_loop
      handlers = {
        add_project: -> { add_project },
        edit_project: -> { edit_project },
        remove_project: -> { remove_project },
        list_projects: -> { list_projects },
      }

      loop do
        choices = build_menu_choices
        action = @prompt.select('What would you like to do?', choices)
        break if action == :exit

        handlers[action]&.call
      end
    end

    def build_menu_choices
      choices = []
      choices << { name: 'Add project', value: :add_project }
      unless @config.empty?
        choices << { name: 'Edit project', value: :edit_project }
        choices << { name: 'Remove project', value: :remove_project }
        choices << { name: 'List projects', value: :list_projects }
      end
      choices << { name: 'Exit', value: :exit }
      choices
    end

    def add_project
      name = @prompt.ask('Project name:', required: true)
      if @config.find_by_name(name)
        @prompt.error("Project '#{name}' already exists.")
        return
      end

      slack_team_id = @prompt.ask('Slack team ID (e.g., T12345ABC):', required: true)
      slack_bot_token = @prompt.mask('Slack bot token (xoxb-...):', required: true)
      github_token = @prompt.mask('GitHub token (ghp_... or github_pat_...):', required: true)
      default_github_org = @prompt.ask('Default GitHub org (optional):')

      warn_token_format(slack_bot_token, github_token)

      @config.add_project(
        name: name,
        slack_team_id: slack_team_id,
        slack_bot_token: slack_bot_token,
        github_token: github_token,
        default_github_org: default_github_org.to_s.empty? ? nil : default_github_org
      )
      @config.save!(@passphrase)
      @prompt.ok("Project '#{name}' added successfully.")
    end

    def edit_project
      name = select_project('Select project to edit:')
      return unless name

      project = @config.find_by_name(name)
      updates = {}

      updates[:name] = @prompt.ask('Project name:', default: project[:name], required: true)
      updates[:slack_team_id] = @prompt.ask('Slack team ID:', default: project[:slack_team_id], required: true)
      updates[:slack_bot_token] = prompt_optional_mask('Slack bot token:', project[:slack_bot_token])
      updates[:github_token] = prompt_optional_mask('GitHub token:', project[:github_token])
      updates[:default_github_org] = @prompt.ask('Default GitHub org:', default: project[:default_github_org])

      updates[:default_github_org] = nil if updates[:default_github_org].to_s.empty?

      warn_token_format(updates[:slack_bot_token], updates[:github_token])

      @config.update_project(name, updates)
      @config.save!(@passphrase)
      @prompt.ok("Project '#{name}' updated successfully.")
    end

    def remove_project
      name = select_project('Select project to remove:')
      return unless name

      return unless @prompt.yes?("Remove project '#{name}'? This cannot be undone.")

      @config.remove_project(name)
      @config.save!(@passphrase)
      @prompt.ok("Project '#{name}' removed.")
    end

    def list_projects
      if @config.empty?
        @prompt.warn('No projects configured.')
        return
      end

      header = ['Name', 'Team ID', 'Slack Token', 'GitHub Token', 'Default Org']
      rows = @config.projects.map do |p|
        [
          p[:name],
          p[:slack_team_id],
          mask_token(p[:slack_bot_token]),
          mask_token(p[:github_token]),
          p[:default_github_org] || '-',
        ]
      end

      table = TTY::Table.new(header: header, rows: rows)
      puts table.render(:unicode, padding: [0, 1], width: terminal_width)
    end

    def select_project(message)
      names = @config.projects.map { |p| p[:name] }
      @prompt.select(message, names)
    end

    def prompt_optional_mask(label, current_value)
      display = mask_token(current_value)
      if @prompt.yes?("#{label} (current: #{display}) Change it?")
        @prompt.mask("New #{label.downcase}", required: true)
      else
        current_value
      end
    end

    def mask_token(token)
      return '-' unless token

      "#{token[0, 8]}..."
    end

    def terminal_width
      TTY::Screen.width
    rescue NoMethodError
      120
    end

    def warn_token_format(slack_token, github_token)
      unless slack_token.start_with?('xoxb-')
        @prompt.warn("Slack token doesn't start with 'xoxb-' — are you sure it's correct?")
      end
      return if github_token.start_with?('ghp_') || github_token.start_with?('github_pat_')

      @prompt.warn("GitHub token doesn't start with 'ghp_' or 'github_pat_' — are you sure it's correct?")
    end
  end
end
