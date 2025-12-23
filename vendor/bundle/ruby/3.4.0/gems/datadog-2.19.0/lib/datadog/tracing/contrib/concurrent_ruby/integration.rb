# frozen_string_literal: true

require_relative '../integration'
require_relative 'patcher'
require_relative 'configuration/settings'

module Datadog
  module Tracing
    module Contrib
      module ConcurrentRuby
        # Describes the ConcurrentRuby integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.9')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :concurrent_ruby
          def self.gem_name
            'concurrent-ruby'
          end

          def self.version
            Gem.loaded_specs['concurrent-ruby'] && Gem.loaded_specs['concurrent-ruby'].version
          end

          def self.loaded?
            # Concurrent::Future is deprecated in favour of Concurrent::Promises::Future
            !defined?(::Concurrent::Promises::Future).nil? || !defined?(::Concurrent::Future).nil?
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
