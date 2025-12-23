# frozen_string_literal: true

require_relative 'security_engine/engine'
require_relative 'security_engine/runner'
require_relative 'processor/rule_loader'
require_relative 'actions_handler'

module Datadog
  module AppSec
    # Core-pluggable component for AppSec
    class Component
      class << self
        def build_appsec_component(settings, telemetry:)
          return if !settings.respond_to?(:appsec) || !settings.appsec.enabled

          ffi_version = Gem.loaded_specs['ffi']&.version
          unless ffi_version
            Datadog.logger.warn('FFI gem is not loaded, AppSec will be disabled.')
            telemetry.error('AppSec: Component not loaded, due to missing FFI gem')

            return
          end

          if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3') && ffi_version < Gem::Version.new('1.16.0')
            Datadog.logger.warn(
              'AppSec is not supported in Ruby versions above 3.3.0 when using `ffi` versions older than 1.16.0, ' \
              'and will be forcibly disabled due to a memory leak in `ffi`. ' \
              'Please upgrade your `ffi` version to 1.16.0 or higher.'
            )
            telemetry.error('AppSec: Component not loaded, ffi version is leaky with ruby > 3.3.0')

            return
          end

          require_libddwaf(telemetry: telemetry)
          Datadog::AppSec::WAF.logger = Datadog.logger if Datadog.logger.debug? && settings.appsec.waf_debug

          # We want to always instrument user events when AppSec is enabled.
          # There could be cases in which users use the DD_APPSEC_ENABLED Env variable to
          # enable AppSec, in that case, Devise is already instrumented.
          # In the case that users do not use DD_APPSEC_ENABLED, we have to instrument it,
          # hence the lines above.
          devise_integration = Datadog::AppSec::Contrib::Devise::Integration.new
          settings.appsec.instrument(:devise) unless devise_integration.patcher.patched?

          security_engine = SecurityEngine::Engine.new(appsec_settings: settings.appsec, telemetry: telemetry)
          new(security_engine: security_engine, telemetry: telemetry)
        rescue
          Datadog.logger.warn('AppSec is disabled, see logged errors above')

          nil
        end

        private

        def require_libddwaf(telemetry:)
          require('libddwaf')
        rescue LoadError => e
          libddwaf_platform = Gem.loaded_specs['libddwaf']&.platform || 'unknown'
          ruby_platforms = Gem.platforms.map(&:to_s)

          error_message = "libddwaf failed to load - installed platform: #{libddwaf_platform}, " \
            "ruby platforms: #{ruby_platforms}"

          Datadog.logger.error("#{error_message}, error #{e.inspect}")
          telemetry.report(e, description: error_message)

          raise e
        end
      end

      attr_reader :security_engine, :telemetry

      def initialize(security_engine:, telemetry:)
        @security_engine = security_engine
        @telemetry = telemetry

        @mutex = Mutex.new
      end

      def reconfigure!
        @mutex.synchronize do
          security_engine.reconfigure!
        end
      end

      def reconfigure_lock(&block)
        @mutex.synchronize(&block)
      end

      def shutdown!
        @mutex.synchronize do
          security_engine.finalize!
          @security_engine = nil
        end
      end
    end
  end
end
