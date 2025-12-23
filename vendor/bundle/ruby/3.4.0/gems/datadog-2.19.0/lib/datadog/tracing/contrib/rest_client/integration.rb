# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module RestClient
        # Description of RestClient integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.8')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :rest_client
          def self.gem_name
            'rest-client'
          end

          def self.version
            Gem.loaded_specs['rest-client'] && Gem.loaded_specs['rest-client'].version
          end

          def self.loaded?
            !defined?(::RestClient::Request).nil?
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
