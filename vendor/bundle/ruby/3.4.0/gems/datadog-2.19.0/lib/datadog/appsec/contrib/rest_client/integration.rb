# frozen_string_literal: true

require_relative '../integration'
require_relative 'patcher'

module Datadog
  module AppSec
    module Contrib
      module RestClient
        # This class defines properties of rest-client AppSec integration
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.8')

          register_as :rest_client

          def self.gem_name
            'rest-client'
          end

          def self.version
            Gem.loaded_specs['rest-client']&.version
          end

          def self.loaded?
            !defined?(::RestClient::Request).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          def self.auto_instrument?
            false
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
