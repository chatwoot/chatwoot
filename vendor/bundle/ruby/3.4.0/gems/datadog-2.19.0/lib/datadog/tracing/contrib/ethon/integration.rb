# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative '../configuration/resolvers/pattern_resolver'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Ethon
        # Description of Ethon integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.11.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :ethon

          def self.version
            Gem.loaded_specs['ethon'] && Gem.loaded_specs['ethon'].version
          end

          def self.loaded?
            !defined?(::Ethon::Easy).nil?
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
