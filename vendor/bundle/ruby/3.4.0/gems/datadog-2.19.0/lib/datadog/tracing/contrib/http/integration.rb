# frozen_string_literal: true

require_relative '../configuration/resolvers/pattern_resolver'
require_relative 'circuit_breaker'
require_relative 'configuration/settings'
require_relative 'patcher'
require_relative '../integration'
require_relative '../../../../datadog/version'

module Datadog
  module Tracing
    module Contrib
      # HTTP integration
      module HTTP
        extend CircuitBreaker

        # Description of HTTP integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Datadog::VERSION::MINIMUM_RUBY_VERSION

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :http, auto_patch: true
          def self.gem_name
            'net-http'
          end

          def self.version
            Gem::Version.new(RUBY_VERSION)
          end

          def self.loaded?
            !defined?(::Net::HTTP).nil?
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
