# frozen_string_literal: true

require "rails"
require "rails/railtie"
require "judoscale/request_middleware"
require "judoscale/rails/config"
require "judoscale/logger"
require "judoscale/reporter"

module Judoscale
  module Rails
    class Railtie < ::Rails::Railtie
      include Judoscale::Logger

      def in_rails_console_or_runner?
        # This is gross, but we can't find a more reliable way to detect if we're in a Rails console/runner.
        caller.any? { |call| call.include?("console_command.rb") || call.include?("runner_command.rb") }
      end

      def in_rake_task?(task_regex)
        top_level_tasks = defined?(::Rake) && Rake.respond_to?(:application) && Rake.application.top_level_tasks || []
        top_level_tasks.any? { |task| task_regex.match?(task) }
      end

      def judoscale_config
        # Disambiguate from Judoscale::Rails::Config
        ::Judoscale::Config.instance
      end

      initializer "Judoscale.logger" do |app|
        judoscale_config.logger = ::Rails.logger
      end

      initializer "Judoscale.request_middleware" do |app|
        app.middleware.insert_before Rack::Runtime, RequestMiddleware
      end

      config.after_initialize do
        if in_rails_console_or_runner?
          logger.debug "No reporting since we're in a Rails console or runner process"
        elsif in_rake_task?(judoscale_config.rake_task_ignore_regex)
          logger.debug "No reporting since we're in a build process"
        elsif judoscale_config.start_reporter_after_initialize
          Reporter.start
        end
      end
    end
  end
end
