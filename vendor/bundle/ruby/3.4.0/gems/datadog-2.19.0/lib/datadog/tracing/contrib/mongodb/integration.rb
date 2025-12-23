# frozen_string_literal: true

require_relative '../integration'
require_relative '../configuration/resolvers/pattern_resolver'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module MongoDB
        # Description of MongoDB integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.1.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :mongo, auto_patch: true
          def self.gem_name
            'mongo'
          end

          def self.version
            Gem.loaded_specs['mongo'] && Gem.loaded_specs['mongo'].version
          end

          def self.loaded?
            !defined?(::Mongo::Monitoring::Global).nil?
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

          def resolver
            @resolver ||= Contrib::Configuration::Resolvers::PatternResolver.new
          end
        end
      end
    end
  end
end
