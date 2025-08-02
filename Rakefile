# frozen_string_literal: true

require 'rake/testtask'
require_relative 'lib/version_helper'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # RuboCop not available
end

# Default task
task default: :test

# Help task - show commonly used tasks
desc 'Show commonly used rake tasks'
task :help do
  puts "\n🚀 slack-github-threads - Available Rake Tasks\n\n"
  
  puts "📋 Development:"
  puts "  rake test         # Run all tests"
  puts "  rake ci           # Run all CI checks (syntax + rubocop + tests)"
  puts "  rake server       # Start the development server"
  puts "  rake install      # Install dependencies"
  puts ""
  
  puts "🔧 Code Quality:"
  puts "  rake lint         # Run linting checks (syntax + rubocop)"
  puts "  rake syntax       # Check Ruby syntax only"
  puts "  rake rubocop      # Run RuboCop linter only"
  puts ""
  
  puts "📦 Release Management:"
  puts "  rake release:preview  # Preview next release and changelog"
  puts "  rake release:patch    # Create patch release (bug fixes)"
  puts "  rake release:minor    # Create minor release (new features)"
  puts "  rake release:major    # Create major release (breaking changes)"
  puts ""
  
  puts "📚 More Information:"
  puts "  rake -T           # Show all available tasks with descriptions"
  puts "  rake -T release   # Show only release-related tasks"
  puts ""
  
  puts "💡 Quick Start:"
  puts "  1. Run 'rake test' to ensure everything works"
  puts "  2. Run 'rake release:preview' to see what would be released"
  puts "  3. Run 'rake release:patch' (or minor/major) to create a release"
  puts ""
end

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
end

# Run specific test files
desc 'Run service tests only'
task :test_services do
  system('ruby -Ilib:test test/services/test_*.rb')
end

desc 'Run app tests only'
task :test_app do
  system('ruby -Ilib:test test/test_app.rb')
end

# Install dependencies
desc 'Install dependencies'
task :install do
  system('bundle install')
end

# Run the application
desc 'Start the development server'
task :server do
  system('bundle exec ruby app.rb')
end

# Check syntax of all Ruby files
desc 'Check syntax of all Ruby files'
task :syntax do
  files = Dir['**/*.rb'].reject { |f| f.start_with?('vendor/') }
  files.each do |file|
    system("ruby -c #{file}") or exit(1)
  end
  puts 'All files have valid syntax!'
end

# Run linting checks (syntax + rubocop)
desc 'Run linting checks (syntax + rubocop)'
task :lint do
  puts '🔍 Running linting checks...'

  puts "\n📋 Step 1: Checking syntax..."
  Rake::Task[:syntax].invoke

  puts "\n🎨 Step 2: Running RuboCop..."
  begin
    Rake::Task[:rubocop].invoke
  rescue NameError
    puts '⚠️  RuboCop not available, skipping...'
  end

  puts "\n✅ All linting checks passed!"
end

# Run all CI checks (same as GitHub Actions)
desc 'Run all CI checks (syntax + rubocop + tests) - same as GitHub Actions'
task :ci do
  puts '🔍 Running CI checks...'

  puts "\n� Step 1: Running linting checks..."
  Rake::Task[:lint].invoke

  puts "\n🧪 Step 2: Running tests..."
  Rake::Task[:test].invoke

  puts "\n✅ All CI checks passed!"
end

# Release management tasks
namespace :release do
  desc 'Generate changelog from git commits since last tag'
  task :changelog, [:version] do |_t, args|
    version = args[:version] || ENV.fetch('VERSION', nil)

    if version.nil?
      puts '❌ Version required. Usage: rake release:changelog[1.1.0] or VERSION=1.1.0 rake release:changelog'
      exit(1)
    end

    puts "📝 Generating changelog for version #{version}..."
    generate_changelog_for_version(version)
  end

  desc 'Create a new release with automatic version bumping'
  task :create, [:bump_type] do |_t, args|
    bump_type = args[:bump_type] || ENV['BUMP_TYPE'] || 'patch'

    unless %w[major minor patch].include?(bump_type)
      puts '❌ Invalid bump type. Use: major, minor, or patch'
      exit(1)
    end

    puts "🚀 Creating #{bump_type} release..."

    # Check if working directory is clean
    unless `git status --porcelain`.strip.empty?
      puts '❌ Working directory is not clean. Please commit or stash your changes.'
      system('git status --short')
      exit(1)
    end

    # Determine next version based on bump type and commit analysis
    version = determine_next_version(bump_type)
    puts "📊 Next version will be: #{version}"

    # Run CI checks
    puts "\n🔍 Running CI checks..."
    Rake::Task[:ci].invoke

    # Generate changelog
    puts "\n📝 Generating changelog..."
    generate_changelog_for_version(version)

    # Create tag
    tag = "v#{version}"
    puts "\n🏷️  Creating tag #{tag}..."
    system('git add CHANGELOG.md') if File.exist?('CHANGELOG.md')
    system("git commit -m 'Update changelog for #{version}'") unless `git status --porcelain CHANGELOG.md`.strip.empty?
    system("git tag -a #{tag} -m 'Release version #{version}'")

    puts "\n✅ Release #{version} created locally!"
    puts "📤 Push with: git push origin main && git push origin #{tag}"
    puts '🌐 Monitor at: https://github.com/markhallen/slack-github-threads/actions'
  end

  desc 'Create a major release (breaking changes)'
  task :major do
    Rake::Task['release:create'].invoke('major')
  end

  desc 'Create a minor release (new features)'
  task :minor do
    Rake::Task['release:create'].invoke('minor')
  end

  desc 'Create a patch release (bug fixes)'
  task :patch do
    Rake::Task['release:create'].invoke('patch')
  end

  desc 'Preview changelog for current unreleased commits'
  task :preview do
    puts '📋 Previewing changelog for unreleased commits...'

    # Get version information using VersionHelper
    info = VersionHelper.version_info
    current_version = info[:current]
    suggested_type = info[:suggested_type]

    puts "\n💡 Suggested release type: #{suggested_type}"
    puts "📊 Current version: #{current_version}"
    puts "🎯 Next patch version would be: #{info[:next_patch]}"
    puts "🎯 Next minor version would be: #{info[:next_minor]}"
    puts "🎯 Next major version would be: #{info[:next_major]}"

    # Show preview of what the changelog would look like
    puts "\n📝 Changelog preview for #{suggested_type} release:"
    puts VersionHelper.generate_changelog_for_version(
      VersionHelper.determine_next_version(suggested_type)
    )
  end

  desc 'Show current version'
  task :version do
    version = VersionHelper.current_version
    puts version ? "Current version: #{version}" : 'No version tags found'
  end
end

# Helper methods for release management (delegating to VersionHelper)
def determine_next_version(bump_type)
  VersionHelper.determine_next_version(bump_type)
end

def get_current_version
  VersionHelper.current_version
end

def bump_version(version, bump_type)
  VersionHelper.bump_version(version, bump_type)
end

def generate_changelog_for_version(version)
  content = VersionHelper.generate_changelog_for_version(version)
  puts content

  # Update CHANGELOG.md if it exists
  if File.exist?('CHANGELOG.md')
    update_changelog_file(version, content)
  else
    create_changelog_file(version, content)
  end
end

def update_changelog_file(version, content)
  changelog_file = 'CHANGELOG.md'
  existing_content = File.read(changelog_file)

  # Insert new section after "## [Unreleased]" or at the beginning
  if existing_content.include?('## [Unreleased]')
    # Find the end of the Unreleased section
    lines = existing_content.split("\n")
    unreleased_end = lines.find_index { |line| line.match?(/^## \[.*\]/) && !line.include?('Unreleased') }
    unreleased_end ||= lines.length

    # Insert new section
    lines[unreleased_end, 0] = content.split("\n")
    updated_content = lines.join("\n")
  else
    # No existing structure, prepend content
    updated_content = content + "\n" + existing_content
  end

  File.write(changelog_file, updated_content)
  puts "✅ Updated #{changelog_file} with version #{version}"
end

def create_changelog_file(version, content)
  changelog_file = 'CHANGELOG.md'
  header = "# Changelog\n\nAll notable changes to this project will be documented in this file.\n\nThe format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),\nand this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).\n\n## [Unreleased]\n\n"

  File.write(changelog_file, header + content)
  puts "✅ Created #{changelog_file} with version #{version}"
end
