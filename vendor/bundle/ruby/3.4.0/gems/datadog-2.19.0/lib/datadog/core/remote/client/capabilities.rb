# frozen_string_literal: true

require_relative '../../utils/base64'
require_relative '../../../appsec/remote'
require_relative '../../../tracing/remote'

module Datadog
  module Core
    module Remote
      class Client
        # Capabilities
        class Capabilities
          attr_reader :products, :capabilities, :receivers, :base64_capabilities

          def initialize(settings, telemetry)
            @capabilities = []
            @products = []
            @receivers = []
            @telemetry = telemetry

            register(settings)

            @base64_capabilities = capabilities_to_base64
          end

          private

          def register(settings)
            if settings.respond_to?(:appsec) && settings.appsec.enabled
              register_capabilities(Datadog::AppSec::Remote.capabilities)
              register_products(Datadog::AppSec::Remote.products)
              register_receivers(Datadog::AppSec::Remote.receivers(@telemetry))
            end

            if settings.respond_to?(:dynamic_instrumentation) && settings.dynamic_instrumentation.enabled
              register_capabilities(Datadog::DI::Remote.capabilities)
              register_products(Datadog::DI::Remote.products)
              register_receivers(Datadog::DI::Remote.receivers(@telemetry))
            end

            register_capabilities(Datadog::Tracing::Remote.capabilities)
            register_products(Datadog::Tracing::Remote.products)
            register_receivers(Datadog::Tracing::Remote.receivers(@telemetry))
          end

          def register_capabilities(capabilities)
            @capabilities.concat(capabilities)
          end

          def register_receivers(receivers)
            @receivers.concat(receivers)
          end

          def register_products(products)
            @products.concat(products)
          end

          def capabilities_to_base64
            return '' if capabilities.empty?

            cap_to_hexs = capabilities.reduce(:|).to_s(16).tap { |s| s.size.odd? && s.prepend('0') }.scan(/\h\h/)
            binary = cap_to_hexs.each_with_object([]) { |hex, acc| acc << hex }.map { |e| e.to_i(16) }.pack('C*')

            Datadog::Core::Utils::Base64.strict_encode64(binary)
          end
        end
      end
    end
  end
end
