# frozen_string_literal: true

require "test_prof"

module TestProf
  module Rails
    # Add `with_logging` and `with_ar_logging helpers`
    module LoggingHelpers
      class << self
        def logger=(logger)
          @logger = logger

          # swap global loggers
          global_loggables.each do |loggable|
            loggable.logger = logger
          end
        end

        def logger
          return @logger if instance_variable_defined?(:@logger)

          @logger = if defined?(ActiveSupport::TaggedLogging)
            ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout))
          elsif defined?(ActiveSupport::Logger)
            ActiveSupport::Logger.new($stdout)
          else
            Logger.new($stdout)
          end
        end

        def global_loggables
          return @global_loggables if instance_variable_defined?(:@global_loggables)

          @global_loggables = []
        end

        def swap_logger!(loggables)
          loggables.each do |loggable|
            loggable.logger = logger
            global_loggables << loggable
          end
        end

        def ar_loggables
          return @ar_loggables if instance_variable_defined?(:@ar_loggables)

          @ar_loggables = [
            ::ActiveRecord::Base,
            ::ActiveSupport::LogSubscriber
          ]
        end

        def all_loggables
          return @all_loggables if instance_variable_defined?(:@all_loggables)

          @all_loggables = [
            ::ActiveSupport::LogSubscriber,
            ::Rails,
            defined?(::ActiveRecord::Base) && ::ActiveRecord::Base,
            defined?(::ActiveJob::Base) && ::ActiveJob::Base,
            defined?(::ActionView::Base) && ::ActionView::Base,
            defined?(::ActionMailer::Base) && ::ActionMailer::Base,
            defined?(::ActionCable::Server::Base.config) && ::ActionCable::Server::Base.config,
            defined?(::ActiveStorage) && ::ActiveStorage
          ].compact
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        def swap_logger(loggables)
          loggables.map do |loggable|
            was_logger = loggable.logger
            loggable.logger = logger
            was_logger
          end
        end

        def restore_logger(was_loggers, loggables)
          loggables.each_with_index do |loggable, i|
            loggable.logger = was_loggers[i]
          end
        end
      end

      # Enable verbose Rails logging within a block
      def with_logging
        *loggers = LoggingHelpers.swap_logger(LoggingHelpers.all_loggables)
        yield
      ensure
        LoggingHelpers.restore_logger(loggers, LoggingHelpers.all_loggables)
      end

      def with_ar_logging
        *loggers = LoggingHelpers.swap_logger(LoggingHelpers.ar_loggables)
        yield
      ensure
        LoggingHelpers.restore_logger(loggers, LoggingHelpers.ar_loggables)
      end
    end
  end
end

if TestProf.rspec?
  RSpec.shared_context "logging:verbose" do
    around(:each) do |ex|
      next with_logging(&ex) if ex.metadata[:log] == true || ex.metadata[:log] == :all

      ex.call
    end
  end

  RSpec.shared_context "logging:active_record" do
    around(:each) do |ex|
      with_ar_logging(&ex)
    end
  end

  RSpec.configure do |config|
    config.include TestProf::Rails::LoggingHelpers
    config.include_context "logging:active_record", log: :ar
    config.include_context "logging:verbose", log: true
  end
end

TestProf.activate("LOG", "all") do
  TestProf.log :info, "Rails verbose logging enabled"
  TestProf::Rails::LoggingHelpers.swap_logger!(TestProf::Rails::LoggingHelpers.all_loggables)
end

TestProf.activate("LOG", "ar") do
  TestProf.log :info, "Active Record verbose logging enabled"
  TestProf::Rails::LoggingHelpers.swap_logger!(TestProf::Rails::LoggingHelpers.ar_loggables)
end
