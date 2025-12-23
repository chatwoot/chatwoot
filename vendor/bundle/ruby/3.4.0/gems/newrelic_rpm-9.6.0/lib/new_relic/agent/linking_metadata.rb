# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    #
    # This module contains helper methods related to gathering linking
    # metadata for use with logs in context.
    module LinkingMetadata
      extend self

      def append_service_linking_metadata(metadata)
        raise ArgumentError, 'Missing argument `metadata`' if metadata.nil?

        config = ::NewRelic::Agent.config

        metadata[ENTITY_NAME_KEY] = config[:app_name][0]
        metadata[ENTITY_TYPE_KEY] = ENTITY_TYPE
        metadata[HOSTNAME_KEY] = Hostname.get

        if entity_guid = config[:entity_guid]
          metadata[ENTITY_GUID_KEY] = entity_guid
        end

        metadata
      end

      def append_trace_linking_metadata(metadata)
        raise ArgumentError, 'Missing argument `metadata`' if metadata.nil?

        if trace_id = Tracer.current_trace_id
          metadata[TRACE_ID_KEY] = trace_id
        end

        if span_id = Tracer.current_span_id
          metadata[SPAN_ID_KEY] = span_id
        end

        metadata
      end
    end
  end
end
