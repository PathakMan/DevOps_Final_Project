require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module DevopsFinalProject
  class Application < Rails::Application
    config.load_defaults 8.1

    # Enable eager loading in production for thread safety and performance
    config.eager_load = ENV["RAILS_ENV"] == "production"

    # Fallback secret key so the container can run without external key files
    config.secret_key_base = ENV.fetch(
      "SECRET_KEY_BASE",
      "a9f8d7e6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9f8"
    )

    # Allow requests from Docker/Kubernetes internal hostnames and healthchecks
    config.hosts.clear

    # Log to STDOUT so Docker can capture application logs
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
