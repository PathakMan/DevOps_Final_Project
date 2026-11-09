# This file is used by Rack-based servers (like Puma) to start the application.
require_relative "config/environment"

run Rails.application
Rails.application.load_server