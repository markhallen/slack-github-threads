#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI script for version operations
# Usage:
#   ruby scripts/version.rb current           # Get current version
#   ruby scripts/version.rb next [type]       # Get next version (auto/major/minor/patch)
#   ruby scripts/version.rb bump [type]       # Same as next (alias)
#   ruby scripts/version.rb analyze           # Analyze commits for suggested release type
#   ruby scripts/version.rb info              # Get all version information

require_relative '../lib/version_helper'

def main
  command = ARGV[0]

  case command
  when 'current'
    handle_current_command
  when 'next', 'bump'
    handle_next_command
  when 'analyze'
    handle_analyze_command
  when 'info'
    handle_info_command
  else
    show_usage
  end
rescue StandardError => e
  warn "Error: #{e.message}"
  exit 1
end

def handle_current_command
  puts VersionHelper.current_version || 'none'
end

def handle_next_command
  release_type = ARGV[1] || 'auto'
  puts VersionHelper.determine_next_version(release_type)
end

def handle_analyze_command
  puts VersionHelper.analyze_commits_for_version_bump
end

def handle_info_command
  info = VersionHelper.version_info
  puts "Current version: #{info[:current]}"
  puts "Suggested release type: #{info[:suggested_type]}"
  puts "Next patch: #{info[:next_patch]}"
  puts "Next minor: #{info[:next_minor]}"
  puts "Next major: #{info[:next_major]}"
end

def show_usage
  puts "Usage: #{$PROGRAM_NAME} <command> [args]"
  puts ''
  puts 'Commands:'
  puts '  current           Get current version'
  puts '  next [type]       Get next version (auto/major/minor/patch)'
  puts '  bump [type]       Same as next (alias)'
  puts '  analyze           Analyze commits for suggested release type'
  puts '  info              Get all version information'
  exit 1
end

main if __FILE__ == $PROGRAM_NAME
