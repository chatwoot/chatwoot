# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'json'

module NewRelic
  module Agent
    module CrossAppTracing
      # The cross app response header for "outgoing" calls
      NR_APPDATA_HEADER = 'X-NewRelic-App-Data'

      # The cross app id header for "outgoing" calls
      NR_ID_HEADER = 'X-NewRelic-ID'

      # The cross app transaction header for "outgoing" calls
      NR_TXN_HEADER = 'X-NewRelic-Transaction'

      NR_MESSAGE_BROKER_ID_HEADER = 'NewRelicID'
      NR_MESSAGE_BROKER_TXN_HEADER = 'NewRelicTransaction'
      NR_MESSAGE_BROKER_SYNTHETICS_HEADER = 'NewRelicSynthetics'

      attr_accessor :is_cross_app_caller, :cross_app_payload, :cat_path_hashes

      def is_cross_app_caller?
        @is_cross_app_caller ||= false
      end

      def is_cross_app_callee?
        !cross_app_payload.nil?
      end

      def is_cross_app?
        is_cross_app_caller? || is_cross_app_callee?
      end

      def cat_trip_id
        cross_app_payload&.referring_trip_id || transaction.guid
      end

      def cross_app_monitor
        NewRelic::Agent.instance.monitors.cross_app_monitor
      end

      def cat_path_hash
        referring_path_hash = cat_referring_path_hash || '0'
        seed = referring_path_hash.to_i(16)
        result = cross_app_monitor.path_hash(transaction.best_name, seed)
        record_cat_path_hash(result)
        result
      end

      def insert_cross_app_header(headers)
        return unless CrossAppTracing.cross_app_enabled?

        @is_cross_app_caller = true
        txn_guid = transaction.guid
        trip_id = cat_trip_id
        path_hash = cat_path_hash

        insert_request_headers(headers, txn_guid, trip_id, path_hash)
      end

      def add_message_cat_headers(headers)
        return unless CrossAppTracing.cross_app_enabled?

        @is_cross_app_caller = true
        insert_message_headers(headers,
          transaction.guid,
          cat_trip_id,
          cat_path_hash,
          transaction.raw_synthetics_header)
      end

      def record_cross_app_metrics
        if (id = cross_app_payload&.id)
          app_time_in_seconds = [
            Process.clock_gettime(Process::CLOCK_REALTIME) - transaction.start_time,
            0.0
          ].max
          NewRelic::Agent.record_metric("ClientApplication/#{id}/all", app_time_in_seconds)
        end
      end

      def assign_cross_app_intrinsics
        transaction.attributes.add_intrinsic_attribute(:trip_id, cat_trip_id)
        transaction.attributes.add_intrinsic_attribute(:path_hash, cat_path_hash)
      end

      private

      def insert_message_headers(headers, txn_guid, trip_id, path_hash, synthetics_header)
        headers[NR_MESSAGE_BROKER_ID_HEADER] = obfuscator.obfuscate(Agent.config[:cross_process_id])
        headers[NR_MESSAGE_BROKER_TXN_HEADER] = obfuscator.obfuscate(::JSON.dump([txn_guid, false, trip_id, path_hash]))
        headers[NR_MESSAGE_BROKER_SYNTHETICS_HEADER] = synthetics_header if synthetics_header
      end

      def record_cat_path_hash(hash)
        @cat_path_hashes ||= []
        if @cat_path_hashes.size < 10 && !@cat_path_hashes.include?(hash)
          @cat_path_hashes << hash
        end
      end

      def cat_referring_path_hash
        cross_app_payload&.referring_path_hash
      end

      def append_cat_info(payload)
        if (referring_guid = cross_app_payload&.referring_guid)
          payload[:referring_transaction_guid] = referring_guid
        end

        return unless transaction.include_guid?

        payload[:guid] = transaction.guid

        return unless is_cross_app?

        trip_id = cat_trip_id
        path_hash = cat_path_hash
        referring_path_hash = cat_referring_path_hash

        payload[:cat_trip_id] = trip_id if trip_id
        payload[:cat_referring_path_hash] = referring_path_hash if referring_path_hash

        if path_hash
          payload[:cat_path_hash] = path_hash

          alternate_path_hashes = cat_path_hashes - [path_hash]
          unless alternate_path_hashes.empty?
            payload[:cat_alternate_path_hashes] = alternate_path_hashes
          end
        end
      end

      ###############
      module_function

      ###############

      def cross_app_enabled?
        valid_cross_process_id? &&
          valid_encoding_key? &&
          cross_application_tracer_enabled?
      end

      def valid_cross_process_id?
        if Agent.config[:cross_process_id] && Agent.config[:cross_process_id].length > 0
          true
        else
          NewRelic::Agent.logger.debug('No cross_process_id configured')
          false
        end
      end

      def valid_encoding_key?
        if Agent.config[:encoding_key] && Agent.config[:encoding_key].length > 0
          true
        else
          NewRelic::Agent.logger.debug('No encoding_key set')
          false
        end
      end

      def cross_application_tracer_enabled?
        !NewRelic::Agent.config[:"distributed_tracing.enabled"] &&
          NewRelic::Agent.config[:"cross_application_tracer.enabled"]
      end

      def obfuscator
        @obfuscator ||= NewRelic::Agent::Obfuscator.new(Agent.config[:encoding_key])
      end

      def insert_request_headers(request, txn_guid, trip_id, path_hash)
        cross_app_id = NewRelic::Agent.config[:cross_process_id]
        txn_data = ::JSON.dump([txn_guid, false, trip_id, path_hash])

        request[NR_ID_HEADER] = obfuscator.obfuscate(cross_app_id)
        request[NR_TXN_HEADER] = obfuscator.obfuscate(txn_data)
      end

      def response_has_crossapp_header?(response)
        if !!response[NR_APPDATA_HEADER]
          true
        else
          NewRelic::Agent.logger.debug("No #{NR_APPDATA_HEADER} header")
          false
        end
      end

      # Extract x-process application data from the specified +response+ and return
      # it as an array of the form:
      #
      #  [
      #    <cross app ID>,
      #    <transaction name>,
      #    <queue time in seconds>,
      #    <response time in seconds>,
      #    <request content length in bytes>,
      #    <transaction GUID>
      #  ]
      def extract_appdata(response)
        appdata = response[NR_APPDATA_HEADER]

        decoded_appdata = obfuscator.deobfuscate(appdata)
        decoded_appdata.set_encoding(::Encoding::UTF_8) if
          decoded_appdata.respond_to?(:set_encoding)

        ::JSON.load(decoded_appdata)
      end

      def valid_cross_app_id?(xp_id)
        !!(xp_id =~ /\A\d+#\d+\z/)
      end

      def message_has_crossapp_request_header?(headers)
        !!headers[NR_MESSAGE_BROKER_ID_HEADER]
      end

      def reject_messaging_cat_headers(headers)
        headers.reject { |k, _| k == NR_MESSAGE_BROKER_ID_HEADER || k == NR_MESSAGE_BROKER_TXN_HEADER }
      end

      def trusts?(id)
        split_id = id.match(/(\d+)#\d+/)
        return false if split_id.nil?

        NewRelic::Agent.config[:trusted_account_ids].include?(split_id.captures.first.to_i)
      end

      def trusted_valid_cross_app_id?(id)
        valid_cross_app_id?(id) && trusts?(id)
      end

      # From inbound request headers
      def assign_intrinsic_transaction_attributes(state)
        # We expect to get the before call to set the id (if we have it) before
        # this, and then write our custom parameter when the transaction starts
        return unless (txn = state.current_transaction)
        return unless (payload = txn.distributed_tracer.cross_app_payload)

        if (cross_app_id = payload.id)
          txn.attributes.add_intrinsic_attribute(:client_cross_process_id, cross_app_id)
        end

        if (referring_guid = payload.referring_guid)
          txn.attributes.add_intrinsic_attribute(:referring_transaction_guid, referring_guid)
        end
      end
    end
  end
end
