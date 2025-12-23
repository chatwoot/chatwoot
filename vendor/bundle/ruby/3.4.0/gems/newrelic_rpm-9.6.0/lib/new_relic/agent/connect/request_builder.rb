# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/environment_report'
require 'new_relic/agent/configuration/event_harvest_config'

module NewRelic
  module Agent
    module Connect
      class RequestBuilder
        def initialize(new_relic_service, config, event_harvest_config, environment_report)
          @service = new_relic_service
          @config = config
          @event_harvest_config = event_harvest_config
          @environment_report = sanitize_environment_report(environment_report)
        end

        # Initializes the hash of settings that we send to the
        # server. Returns a literal hash containing the options
        def connect_payload
          {
            :pid => $$,
            :host => local_host,
            :display_host => Agent.config[:'process_host.display_name'],
            :app_name => Agent.config[:app_name],
            :language => 'ruby',
            :labels => Agent.config.parsed_labels,
            :agent_version => NewRelic::VERSION::STRING,
            :environment => @environment_report,
            :metadata => environment_metadata,
            :settings => Agent.config.to_collector_hash,
            :high_security => Agent.config[:high_security],
            :utilization => UtilizationData.new.to_collector_hash,
            :identifier => "ruby:#{local_host}:#{Agent.config[:app_name].sort.join(',')}",
            :event_harvest_config => @event_harvest_config
          }
        end

        # We've seen objects in the environment report (Rails.env in
        # particular) that can't serialize to JSON. Cope with that here and
        # clear out so downstream code doesn't have to check again.
        def sanitize_environment_report(environment_report)
          return NewRelic::EMPTY_ARRAY unless @service.valid_to_marshal?(environment_report)

          environment_report
        end

        def environment_metadata
          env_copy = {}
          ENV.keys.each { |k| env_copy[k] = ENV[k] if /^NEW_RELIC_METADATA_/.match?(k) }
          env_copy
        end

        def local_host
          NewRelic::Agent::Hostname.get
        end
      end
    end
  end
end
