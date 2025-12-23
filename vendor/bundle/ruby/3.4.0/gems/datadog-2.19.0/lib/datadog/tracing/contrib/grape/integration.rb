# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Grape
        # Description of Grape integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :grape, auto_patch: true

          def self.version
            Gem.loaded_specs['grape'] && Gem.loaded_specs['grape'].version
          end

          def self.loaded?
            !defined?(::Grape).nil? \
              && !defined?(::ActiveSupport::Notifications).nil?
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
