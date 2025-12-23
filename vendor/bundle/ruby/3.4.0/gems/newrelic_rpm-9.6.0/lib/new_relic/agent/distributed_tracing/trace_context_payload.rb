# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/coerce'

module NewRelic
  module Agent
    class TraceContextPayload
      VERSION = 0
      PARENT_TYPE = 0
      DELIMITER = '-'.freeze
      SUPPORTABILITY_PARSE_EXCEPTION = 'Supportability/TraceContext/Parse/Exception'.freeze

      TRUE_CHAR = '1'.freeze
      FALSE_CHAR = '0'.freeze

      PARENT_TYPES = %w[App Browser Mobile].map(&:freeze).freeze

      class << self
        def create(version: VERSION,
          parent_type: PARENT_TYPE,
          parent_account_id: nil,
          parent_app_id: nil,
          id: nil,
          transaction_id: nil,
          sampled: nil,
          priority: nil,
          timestamp: now_ms)

          new(version, parent_type, parent_account_id, parent_app_id, id,
            transaction_id, sampled, priority, timestamp)
        end

        include NewRelic::Coerce

        def from_s(payload_string)
          attrs = payload_string.split(DELIMITER)

          payload = create( \
            version: int!(attrs[0]),
            parent_type: int!(attrs[1]),
            parent_account_id: attrs[2],
            parent_app_id: attrs[3],
            id: value_or_nil(attrs[4]),
            transaction_id: value_or_nil(attrs[5]),
            sampled: value_or_nil(attrs[6]) ? boolean_int!(attrs[6]) == 1 : nil,
            priority: float!(attrs[7]),
            timestamp: int!(attrs[8])
          )
          handle_invalid_payload(message: 'payload missing attributes') unless payload.valid?
          payload
        rescue => e
          handle_invalid_payload(error: e)
          raise
        end

        private

        def now_ms
          Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
        end

        def handle_invalid_payload(error: nil, message: nil)
          NewRelic::Agent.increment_metric(SUPPORTABILITY_PARSE_EXCEPTION)
          if error
            NewRelic::Agent.logger.warn('Error parsing trace context payload', error)
          elsif message
            NewRelic::Agent.logger.warn("Error parsing trace context payload: #{message}")
          end
        end
      end

      attr_accessor :version,
        :parent_type_id,
        :parent_account_id,
        :parent_app_id,
        :id,
        :transaction_id,
        :sampled,
        :priority,
        :timestamp

      alias_method :sampled?, :sampled

      def initialize(version, parent_type_id, parent_account_id, parent_app_id,
        id, transaction_id, sampled, priority, timestamp)
        @version = version
        @parent_type_id = parent_type_id
        @parent_account_id = parent_account_id
        @parent_app_id = parent_app_id
        @id = id
        @transaction_id = transaction_id
        @sampled = sampled
        @priority = priority
        @timestamp = timestamp
      end

      def parent_type
        @parent_type_string ||= PARENT_TYPES[@parent_type_id]
      end

      def valid?
        version \
          && parent_type_id \
          && !parent_account_id.empty? \
          && !parent_app_id.empty? \
          && timestamp
      rescue
        false
      end

      def to_s
        result = version.to_s # required
        result << DELIMITER << parent_type_id.to_s # required
        result << DELIMITER << parent_account_id # required
        result << DELIMITER << parent_app_id # required
        result << DELIMITER << (id || NewRelic::EMPTY_STR)
        result << DELIMITER << (transaction_id || NewRelic::EMPTY_STR)
        result << DELIMITER << (sampled ? TRUE_CHAR : FALSE_CHAR)
        result << DELIMITER << sprintf('%.6f', priority)
        result << DELIMITER << timestamp.to_s # required
        result
      end
    end
  end
end
