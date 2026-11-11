# Puma configuration file
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Default to single-process mode (0 cluster workers)
workers = ENV.fetch("WEB_CONCURRENCY") { 0 }

# Bind to 0.0.0.0 so the server is reachable outside the container
port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV", "production")

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")