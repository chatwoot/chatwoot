# frozen_string_literal: true

require_relative '../analytics'
require_relative 'ext'
require_relative 'configuration/settings'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        # :nodoc:
        module DatadogInterceptor
          # :nodoc:
          class Base < ::GRPC::Interceptor
            def initialize(options = {})
              super
              return unless block_given?

              # Set custom configuration on the interceptor if block is given
              pin_adapter = PinAdapter.new
              yield(pin_adapter)
              Datadog.configure_onto(self, **pin_adapter.options)
            end

            def request_response(**keywords, &block)
              trace(keywords, &block)
            end

            def client_streamer(**keywords, &block)
              trace(keywords, &block)
            end

            def server_streamer(**keywords, &block)
              trace(keywords, &block)
            end

            def bidi_streamer(**keywords, &block)
              trace(keywords, &block)
            end

            private

            def datadog_configuration
              Datadog.configuration.tracing[:grpc]
            end

            def service_name
              Datadog.configuration_for(self, :service_name) || datadog_configuration[:service_name]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def distributed_tracing?
              Datadog.configuration_for(self, :distributed_tracing) || datadog_configuration[:distributed_tracing]
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end

            def on_error
              Datadog.configuration_for(self, :on_error) || datadog_configuration[:on_error]
            end

            # Allows interceptors to define settings using methods instead of `[]`
            class PinAdapter
              OPTIONS = Configuration::Settings.instance_methods(false).freeze

              attr_reader :options

              def initialize
                @options = {}
              end

              def self.add_setter!(option)
                define_method(option) do |value|
                  @options[option.to_s[0...-1].to_sym] = value
                end
              end

              def self.add_getter!(option)
                define_method(option) do
                  return @options[option] if @options.key?(option)

                  Datadog.configuration.tracing[:grpc][option]
                end
              end

              OPTIONS.each do |option|
                if option.to_s[-1] == '='
                  add_setter!(option)
                else
                  add_getter!(option)
                end
              end
            end
          end

          require_relative 'datadog_interceptor/client'
          require_relative 'datadog_interceptor/server'
        end
      end
    end
  end
end
