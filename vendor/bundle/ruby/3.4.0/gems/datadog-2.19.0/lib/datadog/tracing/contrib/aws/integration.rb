# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Aws
        # Description of AWS integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :aws, auto_patch: true
          def self.gem_name
            'aws-sdk'
          end

          def self.version
            if Gem.loaded_specs['aws-sdk']
              Gem.loaded_specs['aws-sdk'].version
            elsif Gem.loaded_specs['aws-sdk-core']
              Gem.loaded_specs['aws-sdk-core'].version
            end
          end

          def self.loaded?
            !defined?(::Seahorse::Client::Base).nil?
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
