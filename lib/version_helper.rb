# frozen_string_literal: true

require 'English'
require 'date'

# Helper module for version management and release operations
module VersionHelper
  # Version pattern for semantic versioning
  VERSION_PATTERN = /^v?(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-]+
                      (?:\.[a-zA-Z0-9\-]+)*))?(?:\+([a-zA-Z0-9\-]+
                      (?:\.[a-zA-Z0-9\-]+)*))?$/x

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

    return nil if latest_tag.empty? || $CHILD_STATUS.exitstatus != 0

    latest_tag
  end

  # Analyze commits since last version to determine suggested release type
  def self.analyze_commits_for_version_bump(since_ref = nil)
    since_ref ||= current_version
    return 'minor' if since_ref.nil?

    commits = get_commits_since(since_ref)
    return 'patch' if commits.empty?

    determine_version_bump_type(commits)
  end

  # Get commits since a reference
  def self.get_commits_since(since_ref)
    `git log #{since_ref}..HEAD --oneline --no-merges 2>/dev/null`.strip.split("\n")
  end

  # Determine version bump type based on commits
  def self.determine_version_bump_type(commits)
    has_breaking = false
    has_feature = false

    commits.each do |commit|
      commit_msg = commit.split(' ', 2)[1] || ''

      if breaking_change?(commit_msg)
        has_breaking = true
      elsif feature_commit?(commit_msg)
        has_feature = true
      end
    end

    return 'major' if has_breaking
    return 'minor' if has_feature

    'patch'
  end

  # Check if commit message indicates a breaking change
  def self.breaking_change?(commit_msg)
    commit_msg.include?('BREAKING CHANGE') || commit_msg.match(/^[^:]+!:/)
  end

  # Check if commit message indicates a feature
  def self.feature_commit?(commit_msg)
    commit_msg.start_with?('feat')
  end

  # Generate changelog entries for a version
  def self.generate_changelog_for_version(version, since_ref = nil)
    since_ref ||= current_version

    commits = get_commits_for_changelog(since_ref)
    categorized_commits = categorize_commits(commits)

    build_changelog_content(version, categorized_commits)
  end

  # Get commits for changelog generation
  def self.get_commits_for_changelog(since_ref)
    if since_ref.nil?
      `git log --oneline --no-merges`.strip.split("\n")
    else
      `git log #{since_ref}..HEAD --oneline --no-merges`.strip.split("\n")
    end
  end

  # Categorize commits by type
  def self.categorize_commits(commits)
    categories = {
      features: [],
      fixes: [],
      breaking_changes: [],
      other_changes: [],
    }

    commits.reverse.each do |commit|
      _sha, message = commit.split(' ', 2)
      next unless message

      categorize_single_commit(message, categories)
    end

    categories
  end

  # Categorize a single commit message
  def self.categorize_single_commit(message, categories)
    case message
    when /^feat(\(.+\))?!?:/
      if message.include?('!') || message.include?('BREAKING CHANGE')
        categories[:breaking_changes] << format_commit_message(message, /^feat(\(.+\))?!?: /)
      else
        categories[:features] << format_commit_message(message, /^feat(\(.+\))?: /)
      end
    when /^fix(\(.+\))?:/
      categories[:fixes] << format_commit_message(message, /^fix(\(.+\))?: /)
    when /BREAKING CHANGE/
      categories[:breaking_changes] << "- #{message}"
    else
      categories[:other_changes] << "- #{message}"
    end
  end

  # Format commit message by removing prefix
  def self.format_commit_message(message, prefix_pattern)
    "- #{message.sub(prefix_pattern, '')}"
  end

  # Build changelog content from categorized commits
  def self.build_changelog_content(version, categories)
    content = []
    content << "## [#{version}] - #{Date.today.strftime('%Y-%m-%d')}"
    content << ''

    add_changelog_section(content, '### ⚠️ BREAKING CHANGES', categories[:breaking_changes])
    add_changelog_section(content, '### ✨ Features', categories[:features])
    add_changelog_section(content, '### 🐛 Bug Fixes', categories[:fixes])
    add_changelog_section(content, '### 🔧 Other Changes', categories[:other_changes])

    content.join("\n")
  end

  # Add a section to changelog content if items exist
  def self.add_changelog_section(content, header, items)
    return if items.empty?

    content << header
    content << ''
    content.concat(items)
    content << ''
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
