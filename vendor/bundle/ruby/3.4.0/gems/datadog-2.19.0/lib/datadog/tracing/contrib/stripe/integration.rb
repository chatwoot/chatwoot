# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Stripe
        # Description of Stripe integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('5.15.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :stripe

          def self.version
            Gem.loaded_specs['stripe'] && Gem.loaded_specs['stripe'].version
          end

          def self.loaded?
            !defined?(::Stripe).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
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
