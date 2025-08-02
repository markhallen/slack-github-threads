# frozen_string_literal: true

require 'date'

# Helper module for version management and release operations
module VersionHelper
  # Version pattern for semantic versioning
  VERSION_PATTERN = /^v?(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*))?(?:\+([a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*))?$/

  # Bump version based on release type
  def self.bump_version(current_version, release_type)
    return '1.0.0' if current_version.nil? || current_version == 'none'

    # Remove 'v' prefix if present
    version_string = current_version.sub(/^v/, '')

    match = version_string.match(VERSION_PATTERN)
    raise "Invalid version format: #{current_version}" unless match

    major = match[1].to_i
    minor = match[2].to_i
    patch = match[3].to_i

    case release_type.to_s.downcase
    when 'major'
      "#{major + 1}.0.0"
    when 'minor'
      "#{major}.#{minor + 1}.0"
    when 'patch'
      "#{major}.#{minor}.#{patch + 1}"
    else
      raise "Invalid release type: #{release_type}"
    end
  end

  # Get the current version from git tags
  def self.current_version
    # Get the latest tag that looks like a version
    latest_tag = `git describe --tags --abbrev=0 --match="v*" 2>/dev/null`.strip

    return nil if latest_tag.empty? || $?.exitstatus != 0

    latest_tag
  end

  # Analyze commits since last version to determine suggested release type
  def self.analyze_commits_for_version_bump(since_ref = nil)
    since_ref ||= current_version

    if since_ref.nil?
      # No previous version, suggest minor for initial release
      return 'minor'
    end

    # Get commits since the reference
    commits = `git log #{since_ref}..HEAD --oneline --no-merges 2>/dev/null`.strip.split("\n")

    return 'patch' if commits.empty?

    has_breaking = false
    has_feature = false

    commits.each do |commit|
      commit_msg = commit.split(' ', 2)[1] || ''

      # Check for breaking changes
      if commit_msg.include?('BREAKING CHANGE') || commit_msg.match(/^[^:]+!:/)
        has_breaking = true
      elsif commit_msg.start_with?('feat')
        has_feature = true
      end
    end

    return 'major' if has_breaking
    return 'minor' if has_feature

    'patch' # Default for fixes and other changes
  end

  # Generate changelog entries for a version
  def self.generate_changelog_for_version(version, since_ref = nil)
    since_ref ||= current_version

    commits = if since_ref.nil?
                `git log --oneline --no-merges`.strip.split("\n")
              else
                `git log #{since_ref}..HEAD --oneline --no-merges`.strip.split("\n")
              end

    # Categorize commits
    features = []
    fixes = []
    breaking_changes = []
    other_changes = []

    commits.reverse.each do |commit|
      _sha, message = commit.split(' ', 2)
      next unless message

      case message
      when /^feat(\(.+\))?!?:/
        if message.include?('!') || message.include?('BREAKING CHANGE')
          breaking_changes << "- #{message.sub(/^feat(\(.+\))?!?: /, '')}"
        else
          features << "- #{message.sub(/^feat(\(.+\))?: /, '')}"
        end
      when /^fix(\(.+\))?:/
        fixes << "- #{message.sub(/^fix(\(.+\))?: /, '')}"
      when /BREAKING CHANGE/
        breaking_changes << "- #{message}"
      else
        # Include other conventional commit types or generic messages
        other_changes << "- #{message}"
      end
    end

    # Build changelog content
    changelog_content = []
    changelog_content << "## [#{version}] - #{Date.today.strftime('%Y-%m-%d')}"
    changelog_content << ''

    unless breaking_changes.empty?
      changelog_content << '### ⚠️ BREAKING CHANGES'
      changelog_content << ''
      changelog_content.concat(breaking_changes)
      changelog_content << ''
    end

    unless features.empty?
      changelog_content << '### ✨ Features'
      changelog_content << ''
      changelog_content.concat(features)
      changelog_content << ''
    end

    unless fixes.empty?
      changelog_content << '### 🐛 Bug Fixes'
      changelog_content << ''
      changelog_content.concat(fixes)
      changelog_content << ''
    end

    unless other_changes.empty?
      changelog_content << '### 🔧 Other Changes'
      changelog_content << ''
      changelog_content.concat(other_changes)
      changelog_content << ''
    end

    changelog_content.join("\n")
  end

  # Determine the next version based on commits
  def self.determine_next_version(release_type = 'auto')
    current = current_version

    if release_type == 'auto'
      suggested_type = analyze_commits_for_version_bump(current)
      bump_version(current, suggested_type)
    else
      bump_version(current, release_type)
    end
  end

  # Get version information as a hash
  def self.version_info
    current = current_version
    {
      current: current || 'none',
      suggested_type: analyze_commits_for_version_bump(current),
      next_patch: bump_version(current, 'patch'),
      next_minor: bump_version(current, 'minor'),
      next_major: bump_version(current, 'major'),
    }
  end
end
