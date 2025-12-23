# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'json'
require 'new_relic/agent/hostname'

module NewRelic
  module Agent
    module Logging
      # This class can be used as the formatter for an existing logger.  It
      # decorates log messages with trace and entity metadata, and formats each
      # log messages as a JSON object.
      #
      # It can be added to a Rails application like this:
      #
      #   require 'newrelic_rpm'
      #
      #   Rails.application.configure do
      #     config.log_formatter = ::NewRelic::Agent::Logging::DecoratingFormatter.new
      #   end
      #
      # @api public
      class DecoratingFormatter < ::Logger::Formatter
        MESSAGE_ELEMENT = 'message'
        LOG_LEVEL_ELEMENT = 'log_level'
        PROG_NAME_ELEMENT = 'prog_name'
        ELEMENTS = ['app_name', 'entity_type', 'hostname', 'entity_guid', 'trace_id', 'span_id', MESSAGE_ELEMENT,
          LOG_LEVEL_ELEMENT, PROG_NAME_ELEMENT].freeze
        TIMESTAMP_KEY = 'timestamp'
        MESSAGE_KEY = 'message'
        LOG_LEVEL_KEY = 'log.level'
        LOG_NAME_KEY = 'logger.name'
        NEWLINE = "\n"

        QUOTE = '"'
        COLON = ':'
        COMMA = ','
        CLOSING_BRACE = '}'
        REPLACEMENT_CHAR = '�'

        def initialize
          Agent.config.register_callback(:app_name) do
            @app_name = nil
          end
        end

        def call(severity, time, progname, msg)
          message = +'{'
          ELEMENTS.each do |element|
            args = case element
                   when MESSAGE_ELEMENT then [message, msg]
                   when LOG_LEVEL_ELEMENT then [message, severity]
                   when PROG_NAME_ELEMENT then [message, progname]
                   else [message]
            end

            send("add_#{element}", *args)
          end
          message << COMMA
          message << QUOTE << TIMESTAMP_KEY << QUOTE << COLON << (time.to_f * 1000).round.to_s
          message << CLOSING_BRACE << NEWLINE
        end

        def clear_tags!
          # No-op; just avoiding issues with act-fluent-logger-rails
        end

        private

        def add_app_name(message)
          return unless app_name

          add_key_value(message, ENTITY_NAME_KEY, app_name)
          message << COMMA
        end

        def add_entity_type(message)
          add_key_value(message, ENTITY_TYPE_KEY, ENTITY_TYPE)
          message << COMMA
        end

        def add_hostname(message)
          add_key_value(message, HOSTNAME_KEY, Hostname.get)
        end

        def add_entity_guid(message)
          return unless entity_guid = Agent.config[:entity_guid]

          message << COMMA
          add_key_value(message, ENTITY_GUID_KEY, entity_guid)
        end

        def add_trace_id(message)
          return unless trace_id = Tracer.trace_id

          message << COMMA
          add_key_value(message, TRACE_ID_KEY, trace_id)
        end

        def add_span_id(message)
          return unless span_id = Tracer.span_id

          message << COMMA
          add_key_value(message, SPAN_ID_KEY, span_id)
        end

        def add_message(message, msg)
          message << COMMA
          message << QUOTE << MESSAGE_KEY << QUOTE << COLON << escape(msg)
          message << COMMA
        end

        def add_log_level(message, severity)
          add_key_value(message, LOG_LEVEL_KEY, severity)
        end

        def add_prog_name(message, progname)
          return unless progname

          message << COMMA
          add_key_value(message, LOG_NAME_KEY, progname)
        end

        def app_name
          @app_name ||= Agent.config[:app_name][0]
        end

        def add_key_value(message, key, value)
          message << QUOTE << key << QUOTE << COLON << QUOTE << value << QUOTE
        end

        def escape(message)
          message = message.to_s unless message.is_a?(String)
          unless message.encoding == Encoding::UTF_8 && message.valid_encoding?
            message = message.encode(
              Encoding::UTF_8,
              invalid: :replace,
              undef: :replace,
              replace: REPLACEMENT_CHAR
            )
          end
          message.to_json
        end
      end

      # This logger decorates logs with trace and entity metadata, and emits log
      # messages formatted as JSON objects.  It extends the Logger class from
      # the Ruby standard library, and accepts the same constructor parameters.
      #
      # It aliases the `:info` message to overwrite the `:write` method, so it
      # can be used in Rack applications that expect the logger to be a file-like
      # object.
      #
      # It can be added to an application like this:
      #
      #   require 'newrelic_rpm'
      #
      #   config.logger = NewRelic::Agent::Logging::DecoratingLogger.new "log/application.log"
      #
      # @api public
      class DecoratingLogger < (defined?(::ActiveSupport) && defined?(::ActiveSupport::Logger) ? ::ActiveSupport::Logger : ::Logger)
        alias :write :info

        # Positional and Keyword arguments are separated beginning with Ruby 2.7
        # Signature of ::Logger constructor changes in Ruby 2.4 to have both positional and keyword args
        # We pivot on Ruby 2.7 for widest supportability with least amount of hassle.
        if RUBY_VERSION < '2.7.0'
          def initialize(*args)
            super(*args)
            self.formatter = DecoratingFormatter.new
          end
        else
          def initialize(*args, **kwargs)
            super(*args, **kwargs)
            self.formatter = DecoratingFormatter.new
          end
        end
      end
    end
  end
end
