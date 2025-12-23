# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'
require_relative 'cache/redis'
require_relative '../rails/ext'
require_relative '../../../core/contrib/rails/utils'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        # Describes the ActiveSupport integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Contrib::Rails::Ext::MINIMUM_VERSION

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :active_support, auto_patch: false
          def self.gem_name
            'activesupport'
          end

          def self.version
            Gem.loaded_specs['activesupport'] && Gem.loaded_specs['activesupport'].version
          end

          def self.loaded?
            !defined?(::ActiveSupport).nil?
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
            ActiveSupport::Patcher
          end
        end
      end
    end
  end
end
