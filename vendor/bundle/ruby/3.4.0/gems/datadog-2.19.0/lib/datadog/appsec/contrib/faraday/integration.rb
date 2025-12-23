# frozen_string_literal: true

require_relative '../integration'

require_relative 'patcher'

module Datadog
  module AppSec
    module Contrib
      module Faraday
        # This class provides helper methods that are used when patching Faraday
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.14.0')

          register_as :faraday, auto_patch: true

          def self.version
            Gem.loaded_specs['faraday']&.version
          end

          def self.loaded?
            !defined?(::Faraday).nil?
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
