# frozen_string_literal: true

require_relative '../integration'
require_relative 'patcher'

module Datadog
  module AppSec
    module Contrib
      module Excon
        # This class provides helper methods that are used when patching Excon
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.50.0')

          register_as :excon

          def self.version
            Gem.loaded_specs['excon']&.version
          end

          def self.loaded?
            !defined?(::Excon).nil?
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
