# frozen_string_literal: true

require "sentry/rails/tracing/abstract_subscriber"

module Sentry
  module Rails
    module Tracing
      class ActiveRecordSubscriber < AbstractSubscriber
        EVENT_NAMES = ["sql.active_record"].freeze
        SPAN_PREFIX = "db."
        SPAN_ORIGIN = "auto.db.rails"
        EXCLUDED_EVENTS = ["SCHEMA", "TRANSACTION"].freeze

        SUPPORT_SOURCE_LOCATION = ActiveSupport::BacktraceCleaner.method_defined?(:clean_frame)

        if SUPPORT_SOURCE_LOCATION
          class_attribute :backtrace_cleaner, default: (ActiveSupport::BacktraceCleaner.new.tap do |cleaner|
            cleaner.add_silencer { |line| line.include?("sentry-ruby/lib") || line.include?("sentry-rails/lib") }
          end)
        end

        class << self
          def subscribe!
            record_query_source = SUPPORT_SOURCE_LOCATION && Sentry.configuration.rails.enable_db_query_source
            query_source_threshold = Sentry.configuration.rails.db_query_source_threshold_ms

            subscribe_to_event(EVENT_NAMES) do |event_name, duration, payload|
              next if EXCLUDED_EVENTS.include? payload[:name]

              record_on_current_span(
                op: SPAN_PREFIX + event_name,
                origin: SPAN_ORIGIN,
                start_timestamp: payload[START_TIMESTAMP_NAME],
                description: payload[:sql],
                duration: duration
              ) do |span|
                span.set_tag(:cached, true) if payload.fetch(:cached, false) # cached key is only set for hits in the QueryCache, from Rails 5.1

                connection = payload[:connection]

                if payload[:connection_id]
                  span.set_data(:connection_id, payload[:connection_id])

                  # we fallback to the base connection on rails < 6.0.0 since the payload doesn't have it
                  connection ||= ActiveRecord::Base.connection_pool.connections.find { |conn| conn.object_id == payload[:connection_id] }
                end

                next unless connection

                db_config =
                  if connection.pool.respond_to?(:db_config)
                    connection.pool.db_config.configuration_hash
                  elsif connection.pool.respond_to?(:spec)
                    connection.pool.spec.config
                  end

                next unless db_config

                span.set_data(Span::DataConventions::DB_SYSTEM, db_config[:adapter]) if db_config[:adapter]
                span.set_data(Span::DataConventions::DB_NAME, db_config[:database]) if db_config[:database]
                span.set_data(Span::DataConventions::SERVER_ADDRESS, db_config[:host]) if db_config[:host]
                span.set_data(Span::DataConventions::SERVER_PORT, db_config[:port]) if db_config[:port]
                span.set_data(Span::DataConventions::SERVER_SOCKET_ADDRESS, db_config[:socket]) if db_config[:socket]

                next unless record_query_source

                # both duration and query_source_threshold are in ms
                next unless duration >= query_source_threshold

                source_location = query_source_location

                if source_location
                  backtrace_line = Sentry::Backtrace::Line.parse(source_location)
                  span.set_data(Span::DataConventions::FILEPATH, backtrace_line.file) if backtrace_line.file
                  span.set_data(Span::DataConventions::LINENO, backtrace_line.number) if backtrace_line.number
                  span.set_data(Span::DataConventions::FUNCTION, backtrace_line.method) if backtrace_line.method
                  # Only JRuby has namespace in the backtrace
                  span.set_data(Span::DataConventions::NAMESPACE, backtrace_line.module_name) if backtrace_line.module_name
                end
              end
            end
          end

          # Thread.each_caller_location is an API added in Ruby 3.2 that doesn't always collect the entire stack like
          # Kernel#caller or #caller_locations do. See https://github.com/rails/rails/pull/49095 for more context.
          if SUPPORT_SOURCE_LOCATION && Thread.respond_to?(:each_caller_location)
            def query_source_location
              Thread.each_caller_location do |location|
                frame = backtrace_cleaner.clean_frame(location)
                return frame if frame
              end
              nil
            end
          else
            # Since Sentry is mostly used in production, we don't want to fallback to the slower implementation
            # and adds potentially big overhead to the application.
            def query_source_location
              nil
            end
          end
        end
      end
    end
  end
end
