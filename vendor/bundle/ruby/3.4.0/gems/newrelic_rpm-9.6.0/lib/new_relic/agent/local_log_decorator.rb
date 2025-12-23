# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    # This module contains helper methods related to decorating log messages
    module LocalLogDecorator
      extend self

      def decorate(message)
        return message unless decorating_enabled?

        metadata = NewRelic::Agent.linking_metadata
        formatted_metadata = " NR-LINKING|#{metadata[ENTITY_GUID_KEY]}|#{metadata[HOSTNAME_KEY]}|" \
                             "#{metadata[TRACE_ID_KEY]}|#{metadata[SPAN_ID_KEY]}|" \
                             "#{escape_entity_name(metadata[ENTITY_NAME_KEY])}|"

        message.partition("\n").insert(1, formatted_metadata).join
      end

      private

      def decorating_enabled?
        NewRelic::Agent.config[:'application_logging.enabled'] &&
          NewRelic::Agent::Instrumentation::Logger.enabled? &&
          NewRelic::Agent.config[:'application_logging.local_decorating.enabled']
      end

      def escape_entity_name(entity_name)
        return unless entity_name

        URI::DEFAULT_PARSER.escape(entity_name)
      end
    end
  end
end
