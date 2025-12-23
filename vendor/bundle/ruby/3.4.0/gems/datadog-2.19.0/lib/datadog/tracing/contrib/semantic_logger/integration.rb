# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module SemanticLogger
        # Description of SemanticLogger integration
        class Integration
          include Contrib::Integration

          # v4 had a migration to `named_tags` instead of `payload`
          # and has been out for almost 5 years at this point
          # it's probably reasonable to nudge users to using modern ruby libs
          MINIMUM_VERSION = Gem::Version.new('4.0.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :semantic_logger

          def self.version
            Gem.loaded_specs['semantic_logger'] && Gem.loaded_specs['semantic_logger'].version
          end

          def self.loaded?
            !defined?(::SemanticLogger::Logger).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          # TODO: abstract out the log injection related instrumentation into it's own module so we dont
          # keep having to do these workarounds
          def auto_instrument?
            false
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
