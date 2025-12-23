# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        # Description of GraphQL integration
        class Integration
          include Contrib::Integration

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :graphql, auto_patch: true

          def self.version
            Gem.loaded_specs['graphql'] && Gem.loaded_specs['graphql'].version
          end

          def self.loaded?
            !defined?(::GraphQL).nil?
          end

          # Breaking changes are introduced in `2.2.6` and have been backported to
          #
          # * 1.13.21
          # * 2.0.28
          # * 2.1.11
          #
          def self.compatible?
            super && (
              (version >= Gem::Version.new('1.13.21') && version < Gem::Version.new('2.0')) ||
              (version >= Gem::Version.new('2.0.28') && version < Gem::Version.new('2.1')) ||
              (version >= Gem::Version.new('2.1.11') && version < Gem::Version.new('2.2')) ||
              (version >= Gem::Version.new('2.2.6'))
            )
          end

          def self.trace_supported?
            version >= Gem::Version.new('2.0.19')
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
