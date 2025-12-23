# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/datastores/mongo/event_formatter'

module NewRelic
  module Agent
    module Instrumentation
      class MongodbCommandSubscriber
        MONGODB = 'MongoDB'.freeze
        COLLECTION = 'collection'.freeze

        def started(event)
          begin
            return unless NewRelic::Agent::Tracer.tracing_enabled?

            segments[event.operation_id] = start_segment(event)
          rescue Exception => e
            log_notification_error('started', e)
          end
        end

        ERROR_KEYS = %w[writeErrors writeConcernError writeConcernErrors].freeze

        def error_key_present?(event)
          if reply = event.reply
            ERROR_KEYS.detect { |key| reply[key] }
          end
        rescue
          false
        end

        def completed(event)
          begin
            return unless NewRelic::Agent::Tracer.tracing_enabled?

            segment = segments.delete(event.operation_id)
            return unless segment

            # operations that succeed but have errors return CommandSucceeded
            # with an error_key that is populated with error specifics
            if error_key = error_key_present?(event)
              # taking the last error as there can potentially be many
              attributes = event.reply[error_key][-1]
              segment.notice_error(Mongo::Error.new('%s (%s)' % [attributes['errmsg'], attributes['code']]))

            # failing commands return a CommandFailed event with an error message
            # in the form of "% (%s)" for the message and code
            elsif event.is_a?(Mongo::Monitoring::Event::CommandFailed)
              segment.notice_error(Mongo::Error.new(event.message))
            end
            segment.finish
          rescue Exception => e
            log_notification_error('completed', e)
          end
        end

        alias :succeeded :completed
        alias :failed :completed

        private

        def start_segment(event)
          host = host_from_address(event.address)
          port_path_or_id = port_path_or_id_from_address(event.address)
          segment = NewRelic::Agent::Tracer.start_datastore_segment(
            product: MONGODB,
            operation: operation(event.command_name),
            collection: collection(event),
            host: host,
            port_path_or_id: port_path_or_id,
            database_name: event.database_name
          )
          segment.notice_nosql_statement(generate_statement(event))
          segment
        end

        def operation(command_name)
          # from 2.0 to 2.5, :findandmodify was the command_name
          if command_name == :findandmodify
            :findAndModify
          else
            command_name
          end
        end

        def collection(event)
          event.command[COLLECTION] || event.command[:collection] || event.command.values.first
        end

        def log_notification_error(event_type, error)
          NewRelic::Agent.logger.error("Error during MongoDB #{event_type} event:")
          NewRelic::Agent.logger.log_exception(:error, error)
        end

        def segments
          @segments ||= {}
        end

        def generate_statement(event)
          NewRelic::Agent::Datastores::Mongo::EventFormatter.format(
            event.command_name,
            event.database_name,
            event.command
          )
        end

        UNKNOWN = 'unknown'.freeze
        LOCALHOST = 'localhost'.freeze

        def host_from_address(address)
          if unix_domain_socket?(address.host)
            LOCALHOST
          else
            address.host
          end
        rescue => e
          NewRelic::Agent.logger.debug("Failed to retrieve Mongo host: #{e}")
          UNKNOWN
        end

        def port_path_or_id_from_address(address)
          if unix_domain_socket?(address.host)
            address.host
          else
            address.port
          end
        rescue => e
          NewRelic::Agent.logger.debug("Failed to retrieve Mongo port_path_or_id: #{e}")
          UNKNOWN
        end

        def unix_domain_socket?(host)
          host.start_with?(NewRelic::SLASH)
        end
      end
    end
  end
end
