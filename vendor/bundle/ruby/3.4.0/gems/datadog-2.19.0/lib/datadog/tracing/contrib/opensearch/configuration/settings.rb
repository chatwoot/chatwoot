# frozen_string_literal: true

require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module OpenSearch
        module Configuration
          # Custom settings for the OpenSearch integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            # @!visibility private
            option :analytics_enabled do |o|
              o.type :bool
              o.env Ext::ENV_ANALYTICS_ENABLED
              o.default false
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            option :quantize, default: {}, type: :hash

            option :service_name do |o|
              o.type :string, nilable: true
              o.default do
                Contrib::SpanAttributeSchema.fetch_service_name(
                  Ext::ENV_SERVICE_NAME,
                  Ext::DEFAULT_PEER_SERVICE_NAME
                )
              end
            end

            option :peer_service do |o|
              o.type :string, nilable: true
              o.env Ext::ENV_PEER_SERVICE
            end

            option :resource_pattern do |o|
              o.type :string
              o.env Ext::ENV_RESOURCE_PATTERN
              o.default Ext::DEFAULT_RESOURCE_PATTERN
              o.setter do |value|
                next value if Ext::VALID_RESOURCE_PATTERNS.include?(value)

                Datadog.logger.warn(
                  "Invalid resource pattern: #{value}. " \
                  "Supported values are: #{Ext::VALID_RESOURCE_PATTERNS.join(' | ')}. " \
                  "Using default value: #{Ext::DEFAULT_RESOURCE_PATTERN}."
                )

                Ext::DEFAULT_RESOURCE_PATTERN
              end
            end
          end
        end
      end
    end
  end
end
