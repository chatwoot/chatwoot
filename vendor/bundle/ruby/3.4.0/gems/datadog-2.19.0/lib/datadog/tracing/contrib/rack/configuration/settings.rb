# frozen_string_literal: true

require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Rack
        module Configuration
          # Custom settings for the Rack integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            DEFAULT_HEADERS = {
              response: %w[
                Content-Type
                X-Request-ID
              ]
            }.freeze

            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            # @!visibility private
            option :analytics_enabled do |o|
              o.type :bool, nilable: true
              o.env Ext::ENV_ANALYTICS_ENABLED
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            option :application
            option :distributed_tracing, default: true, type: :bool
            option :headers, default: DEFAULT_HEADERS, type: :hash
            option :middleware_names, default: false, type: :bool
            option :quantize, default: {}, type: :hash
            option :request_queuing do |o|
              o.type :bool
              o.default false
            end

            option :service_name do |o|
              o.type :string, nilable: true
            end

            option :web_service_name, default: Ext::DEFAULT_PEER_WEBSERVER_SERVICE_NAME, type: :string
          end
        end
      end
    end
  end
end
