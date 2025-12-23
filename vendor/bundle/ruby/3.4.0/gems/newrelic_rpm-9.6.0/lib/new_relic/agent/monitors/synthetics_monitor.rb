# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class SyntheticsMonitor < InboundRequestMonitor
      SYNTHETICS_HEADER_KEY = 'HTTP_X_NEWRELIC_SYNTHETICS'
      SYNTHETICS_INFO_HEADER_KEY = 'HTTP_X_NEWRELIC_SYNTHETICS_INFO'

      SUPPORTED_VERSION = 1
      EXPECTED_PAYLOAD_LENGTH = 5

      def on_finished_configuring(events)
        events.subscribe(:before_call, &method(:on_before_call))
      end

      def on_before_call(request) # THREAD_LOCAL_ACCESS
        encoded_header = request[SYNTHETICS_HEADER_KEY]
        info_header = request[SYNTHETICS_INFO_HEADER_KEY]
        return unless encoded_header

        incoming_payload = deserialize_header(encoded_header, SYNTHETICS_HEADER_KEY)

        return unless incoming_payload &&
          SyntheticsMonitor.is_valid_payload?(incoming_payload) &&
          SyntheticsMonitor.is_supported_version?(incoming_payload) &&
          SyntheticsMonitor.is_trusted?(incoming_payload)

        txn = Tracer.current_transaction
        txn.raw_synthetics_header = encoded_header
        txn.raw_synthetics_info_header = info_header
        txn.synthetics_payload = incoming_payload
        txn.synthetics_info_payload = load_json(info_header, SYNTHETICS_INFO_HEADER_KEY)
      end

      def load_json(header, key)
        ::JSON.load(header)
      rescue => err
        NewRelic::Agent.logger.debug("Failure loading json header '#{key}' in #{self.class}, #{err.class}, #{err.message}")
        nil
      end

      class << self
        def is_supported_version?(incoming_payload)
          incoming_payload.first == SUPPORTED_VERSION
        end

        def is_trusted?(incoming_payload)
          account_id = incoming_payload[1]
          Agent.config[:trusted_account_ids].include?(account_id)
        end

        def is_valid_payload?(incoming_payload)
          incoming_payload.length == EXPECTED_PAYLOAD_LENGTH
        end

        def reject_messaging_synthetics_header(headers)
          headers.reject { |k, _| k == CrossAppTracing::NR_MESSAGE_BROKER_SYNTHETICS_HEADER }
        end
      end
    end
  end
end
