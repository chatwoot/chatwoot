# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Configuration
      class ServerSource < DottedHash
        # These keys appear *outside* of the agent_config hash in the connect
        # response, but should still be merged in as config settings to the
        # main agent configuration.
        TOP_LEVEL_KEYS = [
          'account_id',
          'apdex_t',
          'application_id',
          'beacon',
          'browser_key',
          'browser_monitoring.debug',
          'browser_monitoring.loader',
          'browser_monitoring.loader_version',
          'cross_process_id',
          'data_report_period',
          'encoding_key',
          'entity_guid',
          'error_beacon',
          'js_agent_file',
          'js_agent_loader',
          'max_payload_size_in_bytes',
          'primary_application_id',
          'sampling_target',
          'sampling_target_period_in_seconds',
          'trusted_account_ids',
          'trusted_account_key'
        ]

        def initialize(connect_reply, existing_config = {})
          merged_settings = {}

          merge_top_level_keys(merged_settings, connect_reply)
          merge_agent_config_hash(merged_settings, connect_reply)
          fix_transaction_threshold(merged_settings)
          add_event_harvest_config(merged_settings, connect_reply)
          filter_keys(merged_settings)

          apply_feature_gates(merged_settings, connect_reply, existing_config)

          # The value under this key is a hash mapping transaction name strings
          # to apdex_t values. We don't want the nested hash to be flattened
          # as part of the call to super below, so it skips going through
          # merged_settings.
          self[:web_transactions_apdex] = connect_reply['web_transactions_apdex']

          # This causes keys in merged_settings to be symbolized and flattened
          super(merged_settings)
        end

        def merge_top_level_keys(merged_settings, connect_reply)
          TOP_LEVEL_KEYS.each do |key_name|
            if connect_reply[key_name]
              merged_settings[key_name] = connect_reply[key_name]
            end
          end
        end

        def merge_agent_config_hash(merged_settings, connect_reply)
          if connect_reply['agent_config']
            merged_settings.merge!(connect_reply['agent_config'])
          end
        end

        def fix_transaction_threshold(merged_settings)
          # when value is "apdex_f" remove the config and defer to default
          if /apdex_f/i.match?(merged_settings['transaction_tracer.transaction_threshold'].to_s)
            merged_settings.delete('transaction_tracer.transaction_threshold')
          end
        end

        EVENT_HARVEST_CONFIG_SUPPORTABILITY_METRIC_NAMES = {
          :'transaction_events.max_samples_stored' => 'Supportability/EventHarvest/AnalyticEventData/HarvestLimit',
          :'custom_insights_events.max_samples_stored' => 'Supportability/EventHarvest/CustomEventData/HarvestLimit',
          :'error_collector.max_event_samples_stored' => 'Supportability/EventHarvest/ErrorEventData/HarvestLimit',
          :'application_logging.forwarding.max_samples_stored' => 'Supportability/EventHarvest/LogEventData/HarvestLimit',
          :'span_events.max_samples_stored' => 'Supportability/SpanEvent/Limit',
          :event_report_period => 'Supportability/EventHarvest/ReportPeriod',
          :'event_report_period.span_event_data' => 'Supportability/SpanEvent/ReportPeriod'
        }

        def add_event_harvest_config(merged_settings, connect_reply)
          return unless event_harvest_config_is_valid(connect_reply)

          event_harvest_config = EventHarvestConfig.to_config_hash(connect_reply)
          EVENT_HARVEST_CONFIG_SUPPORTABILITY_METRIC_NAMES.each do |config_key, metric_name|
            NewRelic::Agent.record_metric(metric_name, event_harvest_config[config_key])
          end

          merged_settings.merge!(event_harvest_config)
        end

        def event_harvest_config_is_valid(connect_reply)
          event_harvest_config = connect_reply['event_harvest_config']

          if event_harvest_config.nil? \
              || event_harvest_config['harvest_limits'].values.min < 0 \
              || (event_harvest_config['report_period_ms'] / 1000) <= 0
            NewRelic::Agent.logger.warn('Invalid event harvest config found ' \
                'in connect response; using default event report period.')
            false
          else
            true
          end
        end

        def filter_keys(merged_settings)
          merged_settings.delete_if do |key, _|
            setting_spec = DEFAULTS[key.to_sym]
            if setting_spec
              if setting_spec[:allowed_from_server]
                false # it's allowed, so don't delete it
              else
                NewRelic::Agent.logger.warn("Ignoring server-sent config for '#{key}' - this setting cannot be set from the server")
                true # delete it
              end
            else
              NewRelic::Agent.logger.debug("Ignoring unrecognized config key from server: '#{key}'")
              true
            end
          end
        end

        # These feature gates are not intended to be bullet-proof, but only to
        # avoid the overhead of collecting and transmitting additional data if
        # the user's subscription level precludes its use. The server is the
        # ultimate authority regarding subscription levels, so we expect it to
        # do the real enforcement there.
        def apply_feature_gates(merged_settings, connect_reply, existing_config)
          gated_features = {
            'transaction_tracer.enabled' => 'collect_traces',
            'slow_sql.enabled' => 'collect_traces',
            'error_collector.enabled' => 'collect_errors',
            'transaction_events.enabled' => 'collect_analytics_events',
            'custom_insights_events.enabled' => 'collect_custom_events',
            'error_collector.capture_events' => 'collect_error_events',
            'span_events.enabled' => 'collect_span_events'
          }
          gated_features.each do |config_key, gate_key|
            if connect_reply.has_key?(gate_key)
              allowed_by_server = connect_reply[gate_key]
              requested_value = ungated_value(config_key, merged_settings, existing_config)
              effective_value = (allowed_by_server && requested_value)
              merged_settings[config_key] = effective_value
            end
          end
        end

        def ungated_value(key, merged_settings, existing_config)
          merged_settings.has_key?(key) ? merged_settings[key] : existing_config[key.to_sym]
        end
      end
    end
  end
end
