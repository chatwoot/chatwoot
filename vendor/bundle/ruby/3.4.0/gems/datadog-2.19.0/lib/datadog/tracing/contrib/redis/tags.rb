# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative '../ext'
require_relative '../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Tags handles generic common tags assignment.
        module Tags
          class << self
            def set_common_tags(client, span, raw_command)
              if datadog_configuration[:peer_service]
                span.set_tag(
                  Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                  datadog_configuration[:peer_service]
                )
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_COMMAND)

              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, client.host)

              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              # Set analytics sample rate
              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

              span.set_tag Contrib::Ext::DB::TAG_SYSTEM, Ext::TAG_SYSTEM

              span.set_tag Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, client.host
              span.set_tag Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, client.port

              span.set_tag Ext::TAG_DATABASE_INDEX, client.db.to_s
              span.set_tag Ext::TAG_DB, client.db
              span.set_tag Ext::TAG_RAW_COMMAND, raw_command

              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            private

            def datadog_configuration
              Datadog.configuration.tracing[:redis]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end
          end
        end
      end
    end
  end
end
