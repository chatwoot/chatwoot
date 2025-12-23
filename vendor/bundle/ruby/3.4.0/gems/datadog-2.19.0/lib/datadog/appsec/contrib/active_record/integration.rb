# frozen_string_literal: true

require_relative '../integration'
require_relative 'patcher'

module Datadog
  module AppSec
    module Contrib
      module ActiveRecord
        # This class provides helper methods that are used when patching ActiveRecord
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('4')

          register_as :active_record, auto_patch: true

          def self.version
            Gem.loaded_specs['activerecord']&.version
          end

          def self.loaded?
            !defined?(::ActiveRecord).nil?
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
