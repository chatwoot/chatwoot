# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        # Description of Sidekiq integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('3.5.4')
          MINIMUM_SERVER_INTERNAL_TRACING_VERSION = Gem::Version.new('5.2.4')
          MINIMUM_CAPSULE_VERSION = Gem::Version.new('7.0.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :sidekiq

          def self.version
            Gem.loaded_specs['sidekiq'] && Gem.loaded_specs['sidekiq'].version
          end

          def self.loaded?
            !defined?(::Sidekiq).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          # Only patch server internals on v5.2.4+ because that's when loading of
          # `Sidekiq::Launcher` stabilized. Sidekiq 4+ technically can support our
          # patches (with minor adjustments), but in order to avoid explicitly
          # requiring `sidekiq/launcher` ourselves (which could affect gem
          # initialization order), we are limiting this tracing to v5.2.4+.
          def self.compatible_with_server_internal_tracing?
            version >= MINIMUM_SERVER_INTERNAL_TRACING_VERSION
          end

          # Capsules are a new way of configuring Sidekiq that was introduced in version 7
          # that change the way some of the configuration data is exposed. Certain patches
          # are applied differently for versions of Sidekiq that support capsules.
          def self.supports_capsules?
            version >= MINIMUM_CAPSULE_VERSION
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
