# frozen_string_literal: true

require 'date'
require 'json'
require 'rbconfig'
require_relative '../../core/diagnostics/environment_logger'

module Datadog
  module Tracing
    module Diagnostics
      # Collects and logs Tracing diagnostic and error information
      module EnvironmentLogger
        extend Core::Diagnostics::EnvironmentLogging

        def self.collect_and_log!(responses: nil)
          if log?
            log_configuration!('TRACING', EnvironmentCollector.collect_config!.to_json)
            log_debug!('TRACING INTEGRATIONS', EnvironmentCollector.collect_integrations_settings!.to_json)

            if responses
              err_data = EnvironmentCollector.collect_errors!(responses)
              err_data.reject! { |_, v| v.nil? } # Remove empty values from hash output
              log_error!('TRACING', 'Agent Error', err_data.to_json) unless err_data.empty?
            end
          end
        rescue => e
          logger.warn("Failed to collect tracing environment information: #{e} Location: #{Array(e.backtrace).first}")
        end
      end

      # Collects environment information for Tracing diagnostic logging
      module EnvironmentCollector
        class << self
          def collect_config!
            {
              enabled: enabled,
              agent_url: agent_url,
              analytics_enabled: analytics_enabled,
              sample_rate: sample_rate,
              sampling_rules: sampling_rules,
              integrations_loaded: integrations_loaded,
              partial_flushing_enabled: partial_flushing_enabled,
            }
          end

          def collect_errors!(responses)
            {
              agent_error: agent_error(responses)
            }
          end

          # @return [Boolean, nil]
          def enabled
            !!Datadog.configuration.tracing.enabled
          end

          # @return [String, nil] target agent URL for trace flushing
          def agent_url
            # Retrieve the effect agent URL, regardless of how it was configured
            transport = Tracing.send(:tracer).writer.transport

            # return `nil` with IO transport
            return unless transport.respond_to?(:client)

            adapter = transport.client.api.adapter
            adapter.url
          end

          # Error returned by Datadog agent during a tracer flush attempt
          # @return [String] concatenated list of transport errors
          def agent_error(responses)
            error_responses = responses.reject(&:ok?)

            return nil if error_responses.empty?

            error_responses.map(&:inspect).join(',')
          end

          # @return [Boolean, nil] analytics enabled in configuration
          def analytics_enabled
            !!Datadog.configuration.tracing.analytics.enabled
          end

          # @return [Numeric, nil] tracer sample rate configured
          def sample_rate
            sampler = Datadog.configuration.tracing.sampler
            return Datadog.configuration.tracing.sampling.default_rate unless sampler

            sampler.sample_rate(nil) rescue nil
          end

          # DEV: We currently only support SimpleRule instances.
          # DEV: These are the most commonly used rules.
          # DEV: We should expand support for other rules in the future,
          # DEV: although it is tricky to serialize arbitrary rules.
          #
          # @return [Hash, nil] sample rules configured
          def sampling_rules
            sampler = Datadog.configuration.tracing.sampler
            return Datadog.configuration.tracing.sampling.rules unless sampler

            return nil unless sampler.is_a?(Tracing::Sampling::PrioritySampler) &&
              sampler.priority_sampler.is_a?(Tracing::Sampling::RuleSampler)

            sampler.priority_sampler.rules.map do |rule|
              next unless rule.is_a?(Tracing::Sampling::SimpleRule)

              {
                name: rule.matcher.name,
                service: rule.matcher.service,
                sample_rate: rule.sampler.sample_rate(nil)
              }
            end.compact
          end

          # Concatenated list of integrations activated, with their gem version.
          # Example: "rails@6.0.3,rack@2.2.3"
          #
          # @return [String, nil]
          def integrations_loaded
            integrations = instrumented_integrations
            return if integrations.empty?

            integrations.map { |name, integration| "#{name}@#{integration.class.version}" }.join(',')
          end

          # @return [Boolean, nil] partial flushing enabled in configuration
          def partial_flushing_enabled
            !!Datadog.configuration.tracing.partial_flush.enabled
          end

          def collect_integrations_settings!
            instrumented_integrations.each_with_object({}) do |(name, integration), result|
              integration.configuration.to_h.each do |setting, value|
                next if setting == :tracer # Skip internal objects

                # Convert value to a string to avoid custom #to_json
                # handlers possibly causing errors.
                result[:"#{name}_#{setting}"] = value.to_s
              end
            end
          end

          private

          def instrumented_integrations
            # `instrumented_integrations` method is added only if tracing contrib extensions are required.
            # If tracing is used in manual mode without integrations enabled this method does not exist.
            # CI visibility gem datadog-ci uses Datadog::Tracer without requiring datadog/tracing/contrib folder
            # nor enabling any integrations by default which causes EnvironmentCollector to fail.
            return {} unless Datadog.configuration.tracing.respond_to?(:instrumented_integrations)

            Datadog.configuration.tracing.instrumented_integrations
          end
        end
      end
    end
  end
end
