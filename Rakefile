# frozen_string_literal: true

require 'rake/testtask'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # RuboCop not available
end

# Default task
task default: :test

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

# Run all CI checks (same as GitHub Actions)
desc 'Run all CI checks (syntax + rubocop + tests) - same as GitHub Actions'
task :ci do
  puts '🔍 Running CI checks...'

  puts "\n📋 Step 1: Checking syntax..."
  Rake::Task[:syntax].invoke

  puts "\n🎨 Step 2: Running RuboCop..."
  begin
    Rake::Task[:rubocop].invoke
  rescue NameError
    puts '⚠️  RuboCop not available, skipping...'
  end

  puts "\n🧪 Step 3: Running tests..."
  Rake::Task[:test].invoke

  puts "\n✅ All CI checks passed!"
end
