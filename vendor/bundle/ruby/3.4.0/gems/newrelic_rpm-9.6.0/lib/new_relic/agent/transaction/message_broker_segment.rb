# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/segment'
require 'new_relic/agent/distributed_tracing/cross_app_tracing'

module NewRelic
  module Agent
    class Transaction
      class MessageBrokerSegment < Segment
        CONSUME = 'Consume'.freeze
        EXCHANGE = 'Exchange'.freeze
        NAMED = 'Named/'.freeze
        PRODUCE = 'Produce'.freeze
        QUEUE = 'Queue'.freeze
        PURGE = 'Purge'.freeze
        TEMP = 'Temp'.freeze
        TOPIC = 'Topic'.freeze
        UNKNOWN = 'Unknown'.freeze

        DESTINATION_TYPES = [
          :exchange,
          :queue,
          :topic,
          :temporary_queue,
          :temporary_topic,
          :unknown
        ]

        ACTIONS = {
          consume: CONSUME,
          produce: PRODUCE,
          purge: PURGE
        }

        TYPES = {
          exchange: EXCHANGE,
          temporary_queue: QUEUE,
          queue: QUEUE,
          temporary_topic: TOPIC,
          topic: TOPIC,
          unknown: EXCHANGE
        }

        METRIC_PREFIX = 'MessageBroker/'.freeze

        attr_reader :action,
          :destination_name,
          :destination_type,
          :library,
          :headers

        def initialize(action:,
          library:,
          destination_type:,
          destination_name:,
          headers: nil,
          parameters: nil,
          start_time: nil)

          @action = action
          @library = library
          @destination_type = destination_type
          @destination_name = destination_name
          @headers = headers
          super(nil, nil, start_time)
          params.merge!(parameters) if parameters
        end

        def name
          return @name if @name

          @name = METRIC_PREFIX + library
          @name << NewRelic::SLASH << TYPES[destination_type] << NewRelic::SLASH << ACTIONS[action] << NewRelic::SLASH

          if destination_type == :temporary_queue || destination_type == :temporary_topic
            @name << TEMP
          else
            @name << NAMED << destination_name.to_s
          end

          @name
        end

        def transaction_assigned
          if headers && transaction && action == :produce && record_metrics?
            transaction.distributed_tracer.insert_distributed_trace_header(headers)
            transaction.distributed_tracer.insert_cat_headers(headers)
            transaction.distributed_tracer.log_request_headers(headers)
          end
        rescue => e
          NewRelic::Agent.logger.error('Error during message header processing', e)
        end
      end
    end
  end
end
