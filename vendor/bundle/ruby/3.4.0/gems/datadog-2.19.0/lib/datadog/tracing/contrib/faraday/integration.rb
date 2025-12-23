# frozen_string_literal: true

require_relative '../integration'
require_relative '../configuration/resolvers/pattern_resolver'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Faraday
        # Description of Faraday integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.14.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :faraday, auto_patch: true

          def self.version
            Gem.loaded_specs['faraday'] && Gem.loaded_specs['faraday'].version
          end

          def self.loaded?
            !defined?(::Faraday).nil?
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
