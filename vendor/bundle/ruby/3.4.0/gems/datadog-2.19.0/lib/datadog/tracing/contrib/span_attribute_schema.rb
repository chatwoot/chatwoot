# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      # Contains methods for fetching values according to span attributes schema
      module SpanAttributeSchema
        REFLEXIVE_SOURCES = [Tracing::Metadata::Ext::TAG_PEER_SERVICE].freeze
        NO_SOURCE = [].freeze

        def self.fetch_service_name(env, default)
          ENV.fetch(env) do
            if Datadog.configuration.tracing.contrib.global_default_service_name.enabled
              return Datadog.configuration.service
            end

            default
          end
        end

        def self.set_peer_service!(span, sources)
          config = Datadog.configuration.tracing.contrib

          # If `peer_service_defaults` is disabled, we only read peer service from an explicitly set `peer.service` tag
          sources = Datadog::Tracing::Contrib::SpanAttributeSchema::REFLEXIVE_SOURCES unless config.peer_service_defaults

          # Acquire all peer.service values as well as any potential remapping
          peer_service_val, peer_service_source = set_peer_service_from_source(span, sources)
          remap_val = config.peer_service_mapping[peer_service_val]

          # Only continue to setting peer.service if actual source is found
          return false unless peer_service_source

          span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_PEER_SERVICE_SOURCE, peer_service_source)

          # Set peer.service to remapped value if found otherwise normally set peer.service
          if remap_val
            span.set_tag(Tracing::Metadata::Ext::TAG_PEER_SERVICE, remap_val)
            span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_PEER_SERVICE_REMAP, peer_service_val)
          else
            span.set_tag(Tracing::Metadata::Ext::TAG_PEER_SERVICE, peer_service_val)
          end
          true
        end

        # set_peer_service_from_source: Implements the extraction logic to determine the peer.service value
        # based on the list of source tags passed as a parameter.
        #
        # If no values are found, it checks the default list for all spans before returning false for no result
        # Sets the source of where the information for peer.service was extracted from
        # Returns a peer.service value if successfully set or not
        def self.set_peer_service_from_source(span, sources = [])
          # Filter out sources based on existence of peer.service tag
          sources = filter_peer_service_sources(span, sources)

          # Find a possible peer.service source from the list of source tags passed in
          sources.each do |source|
            source_val = span.get_tag(source)
            next unless not_empty_tag?(source_val)

            return source_val, source
          end
          false
        end

        private_class_method :set_peer_service_from_source

        # filter_peer_service_sources: returns filtered sources based on existence of peer.service tag
        # If peer.service exists, we do not read from any other source rather use peer.service as source
        # This is to prevent overwriting of pre-existing peer.service tags
        def self.filter_peer_service_sources(span, sources)
          ps = span.get_tag(Tracing::Metadata::Ext::TAG_PEER_SERVICE)
          # Do not override existing peer.service tag if it exists based on schema version
          return REFLEXIVE_SOURCES if not_empty_tag?(ps)

          # Check that peer.service is only set on spankind client/producer spans
          if (span.get_tag(Tracing::Metadata::Ext::TAG_KIND) == Tracing::Metadata::Ext::SpanKind::TAG_CLIENT) ||
              (span.get_tag(Tracing::Metadata::Ext::TAG_KIND) == Tracing::Metadata::Ext::SpanKind::TAG_PRODUCER)
            return sources
          end

          NO_SOURCE
        end

        private_class_method :filter_peer_service_sources

        def self.not_empty_tag?(tag)
          tag && (tag != '')
        end

        private_class_method :not_empty_tag?
      end
    end
  end
end
