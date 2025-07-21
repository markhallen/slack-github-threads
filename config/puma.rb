# config/puma.rb
port ENV.fetch("PORT") { 80 }
environment ENV.fetch("RACK_ENV") { "production" }

# Number of worker processes
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Number of threads per worker
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Preload the application
preload_app!

# Allow puma to be restarted by `bin/rails restart` command
plugin :tmp_restart
