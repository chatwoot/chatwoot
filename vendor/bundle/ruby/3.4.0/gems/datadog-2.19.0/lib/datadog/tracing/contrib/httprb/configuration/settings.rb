# frozen_string_literal: true

require_relative '../../configuration/settings'
require_relative '../../status_range_matcher'
require_relative '../../status_range_env_parser'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Httprb
        module Configuration
          # Custom settings for the Httprb integration
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

            option :distributed_tracing, default: true, type: :bool

            option :service_name do |o|
              o.default do
                Contrib::SpanAttributeSchema.fetch_service_name(
                  Ext::ENV_SERVICE_NAME,
                  Ext::DEFAULT_PEER_SERVICE_NAME
                )
              end
            end

            option :error_status_codes do |o|
              o.env Ext::ENV_ERROR_STATUS_CODES
              o.default 400...600
              o.setter do |v|
                Tracing::Contrib::StatusRangeMatcher.new(v) if v
              end
              o.env_parser do |v|
                Tracing::Contrib::StatusRangeEnvParser.call(v) if v
              end
            end

            option :peer_service do |o|
              o.type :string, nilable: true
              o.env Ext::ENV_PEER_SERVICE
            end

            option :split_by_domain, default: false, type: :bool
          end
        end
      end
    end
  end
end
