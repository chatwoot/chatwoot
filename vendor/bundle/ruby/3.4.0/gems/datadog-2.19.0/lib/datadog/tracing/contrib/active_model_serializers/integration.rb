# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module ActiveModelSerializers
        # Description of ActiveModelSerializers integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.9.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :active_model_serializers

          def self.version
            Gem.loaded_specs['active_model_serializers'] \
              && Gem.loaded_specs['active_model_serializers'].version
          end

          def self.loaded?
            !defined?(::ActiveModel::Serializer).nil? \
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
