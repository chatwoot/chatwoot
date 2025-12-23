# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Configuration
      module EventHarvestConfig
        extend self

        EVENT_HARVEST_CONFIG_KEY_MAPPING = {
          :analytic_event_data => :'transaction_events.max_samples_stored',
          :custom_event_data => :'custom_insights_events.max_samples_stored',
          :error_event_data => :'error_collector.max_event_samples_stored',
          :log_event_data => :'application_logging.forwarding.max_samples_stored'
        }

        # not including span_event_data here because spans are handled separately in transform_span_event_harvest_config
        EVENT_HARVEST_EVENT_REPORT_PERIOD_KEY_MAPPING = {
          :analytic_event_data => :'transaction_event_data',
          :custom_event_data => :'custom_event_data',
          :error_event_data => :'error_event_data',
          :log_event_data => :'log_event_data'
        }

        def from_config(config)
          {:harvest_limits =>
            EVENT_HARVEST_CONFIG_KEY_MAPPING.merge(
              :span_event_data => :'span_events.max_samples_stored'
            ).inject({}) do |connect_payload, (connect_payload_key, config_key)|
              connect_payload[connect_payload_key] = config[config_key]
              connect_payload
            end}
        end

        def to_config_hash(connect_reply)
          event_harvest_interval = connect_reply['event_harvest_config']['report_period_ms'] / 1000
          config_hash = transform_event_harvest_config_keys(connect_reply, event_harvest_interval)
          config_hash[:event_report_period] = event_harvest_interval
          config_hash = transform_span_event_harvest_config(config_hash, connect_reply)
          config_hash
        end

        private

        def transform_event_harvest_config_keys(connect_reply, event_harvest_interval)
          EVENT_HARVEST_CONFIG_KEY_MAPPING.inject({}) do |event_harvest_config, (connect_payload_key, config_key)|
            if harvest_limit = connect_reply['event_harvest_config']['harvest_limits'][connect_payload_key.to_s]
              event_harvest_config[config_key] = harvest_limit
              report_period_key = :"event_report_period.#{EVENT_HARVEST_EVENT_REPORT_PERIOD_KEY_MAPPING[connect_payload_key]}"
              event_harvest_config[report_period_key] = event_harvest_interval
            end
            event_harvest_config
          end
        end

        def transform_span_event_harvest_config(config_hash, connect_reply)
          if span_harvest = connect_reply['span_event_harvest_config']
            config_hash[:'span_events.max_samples_stored'] = span_harvest['harvest_limit'] if span_harvest['harvest_limit']
            config_hash[:'event_report_period.span_event_data'] = span_harvest['report_period_ms'] if span_harvest['report_period_ms']
          end

          config_hash
        end
      end
    end
  end
end
