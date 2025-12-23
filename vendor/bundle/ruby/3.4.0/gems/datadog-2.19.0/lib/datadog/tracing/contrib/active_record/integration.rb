# frozen_string_literal: true

require_relative 'configuration/resolver'
require_relative 'configuration/settings'
require_relative 'events'
require_relative 'patcher'
require_relative '../component'
require_relative '../integration'
require_relative '../rails/ext'
require_relative '../../../core/contrib/rails/utils'

module Datadog
  module Tracing
    module Contrib
      module ActiveRecord
        # Describes the ActiveRecord integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Contrib::Rails::Ext::MINIMUM_VERSION

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :active_record, auto_patch: false

          def self.gem_name
            'activerecord'
          end

          def self.version
            Gem.loaded_specs['activerecord'] && Gem.loaded_specs['activerecord'].version
          end

          def self.loaded?
            !defined?(::ActiveRecord).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          # enabled by rails integration so should only auto instrument
          # if detected that it is being used without rails
          def auto_instrument?
            !Core::Contrib::Rails::Utils.railtie_supported?
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            ActiveRecord::Patcher
          end

          def resolver
            @resolver ||= Configuration::Resolver.new
          end

          def reset_resolver_cache
            @resolver&.reset_cache if defined?(@resolver)
          end

          Contrib::Component.register('activerecord') do |_config|
            # Ensure resolver cache is reset on configuration change
            Datadog.configuration.tracing.fetch_integration(:active_record).reset_resolver_cache
          end
        end
      end
    end
  end
end
