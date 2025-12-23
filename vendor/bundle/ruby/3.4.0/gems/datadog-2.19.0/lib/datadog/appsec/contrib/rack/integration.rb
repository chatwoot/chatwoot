# frozen_string_literal: true

require_relative '../integration'

require_relative 'patcher'
require_relative 'request_middleware'
require_relative 'request_body_middleware'

module Datadog
  module AppSec
    module Contrib
      module Rack
        # Description of Rack integration
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.1.0')

          register_as :rack, auto_patch: false

          def self.version
            Gem.loaded_specs['rack']&.version
          end

          def self.loaded?
            !defined?(::Rack).nil?
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
