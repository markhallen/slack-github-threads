require 'rake/testtask'

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
task :test_services do
  system('ruby -Ilib:test test/services/test_*.rb')
end

task :test_app do
  system('ruby -Ilib:test test/test_app.rb')
end

# Install dependencies
task :install do
  system('bundle install')
end

# Run the application
task :server do
  system('bundle exec ruby app_new.rb')
end

# Check syntax of all Ruby files
task :syntax do
  files = Dir['**/*.rb'].reject { |f| f.start_with?('vendor/') }
  files.each do |file|
    system("ruby -c #{file}") or exit(1)
  end
  puts "All files have valid syntax!"
end
