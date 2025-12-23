# frozen_string_literal: true

require 'json'
require_relative 'rate_limiter'
require_relative 'compressed_json'

module Datadog
  module AppSec
    # AppSec event
    module Event
      DERIVATIVE_SCHEMA_KEY_PREFIX = '_dd.appsec.s.'
      DERIVATIVE_SCHEMA_MAX_COMPRESSED_SIZE = 25000
      ALLOWED_REQUEST_HEADERS = %w[
        x-forwarded-for
        x-client-ip
        x-real-ip
        x-forwarded
        x-cluster-client-ip
        forwarded-for
        forwarded
        via
        true-client-ip
        content-length
        content-type
        content-encoding
        content-language
        host
        user-agent
        accept
        accept-encoding
        accept-language
      ].freeze

      ALLOWED_RESPONSE_HEADERS = %w[
        content-length
        content-type
        content-encoding
        content-language
      ].freeze

      class << self
        def tag_and_keep!(context, waf_result)
          # We want to keep the trace in case of security event
          context.trace&.keep!

          if context.span
            if waf_result.actions.key?('block_request') || waf_result.actions.key?('redirect_request')
              context.span.set_tag('appsec.blocked', 'true')
            end

            context.span.set_tag('appsec.event', 'true')
          end

          add_distributed_tags(context.trace)
        end

        def record(context, request: nil, response: nil)
          return if context.events.empty? || context.span.nil?

          Datadog::AppSec::RateLimiter.thread_local.limit do
            context.events.group_by(&:trace).each do |trace, event_group|
              unless trace
                next Datadog.logger.debug do
                  "AppSec: Cannot record event group with #{event_group.count} events because it has no trace"
                end
              end

              if event_group.any? { |event| event.attack? || event.schema? }
                trace.keep!
                trace[Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER] = Tracing::Sampling::Ext::Decision::ASM

                context.span['_dd.origin'] = 'appsec'
                context.span.set_tags(request_tags(request)) if request
                context.span.set_tags(response_tags(response)) if response
              end

              context.span.set_tags(waf_tags(event_group))
            end
          end
        end

        private

        def request_tags(request)
          tags = {}

          tags['http.host'] = request.host if request.host
          tags['http.useragent'] = request.user_agent if request.user_agent
          tags['network.client.ip'] = request.remote_addr if request.remote_addr

          request.headers.each_with_object(tags) do |(name, value), memo|
            next unless ALLOWED_REQUEST_HEADERS.include?(name)

            memo["http.request.headers.#{name}"] = value
          end
        end

        def response_tags(response)
          response.headers.each_with_object({}) do |(name, value), memo|
            next unless ALLOWED_RESPONSE_HEADERS.include?(name)

            memo["http.response.headers.#{name}"] = value
          end
        end

        def waf_tags(security_events)
          triggers = []

          tags = security_events.each_with_object({}) do |security_event, memo|
            triggers.concat(security_event.waf_result.events)

            security_event.waf_result.derivatives.each do |key, value|
              next memo[key] = value unless key.start_with?(DERIVATIVE_SCHEMA_KEY_PREFIX)

              value = CompressedJson.dump(value)
              next if value.nil?

              if value.size >= DERIVATIVE_SCHEMA_MAX_COMPRESSED_SIZE
                Datadog.logger.debug { "AppSec: Schema key '#{key}' will not be included into span tags due to it's size" }
                next
              end

              memo[key] = value
            end
          end

          tags['_dd.appsec.json'] = json_parse({triggers: triggers}) unless triggers.empty?
          tags
        end

        # NOTE: Handling of Encoding::UndefinedConversionError is added as a quick fix to
        #       the issue between Ruby encoded strings and libddwaf produced events and now
        #       is under investigation.
        def json_parse(value)
          JSON.dump(value)
        rescue ArgumentError, Encoding::UndefinedConversionError, JSON::JSONError => e
          AppSec.telemetry.report(e, description: 'AppSec: Failed to convert value into JSON')

          nil
        end

        # Propagate to downstream services the information that the current distributed trace is
        # containing at least one ASM security event.
        def add_distributed_tags(trace)
          return unless trace

          trace.set_tag(
            Datadog::Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER,
            Datadog::Tracing::Sampling::Ext::Decision::ASM
          )
          trace.set_distributed_source(Datadog::AppSec::Ext::PRODUCT_BIT)
        end
      end
    end
  end
end
