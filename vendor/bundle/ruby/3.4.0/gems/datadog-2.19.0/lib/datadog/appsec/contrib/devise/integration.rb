# frozen_string_literal: true

require_relative '../integration'
require_relative 'patcher'

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Description of Devise integration
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('3.2.1')

          register_as :devise, auto_patch: true

          def self.version
            Gem.loaded_specs['devise']&.version
          end

          def self.loaded?
            !defined?(::Devise).nil?
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
