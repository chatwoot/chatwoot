# frozen_string_literal: true

require_relative '../integration'

require_relative 'patcher'
require_relative 'request_middleware'

module Datadog
  module AppSec
    module Contrib
      module Rails
        # Description of Rails integration
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('4')

          register_as :rails, auto_patch: false

          def self.version
            Gem.loaded_specs['railties']&.version
          end

          def self.loaded?
            !defined?(::Rails).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          def self.auto_instrument?
            true
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
