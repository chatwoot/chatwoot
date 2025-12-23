# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module OpenSearch
        # Description of OpenSearch integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.0.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :opensearch, auto_patch: true
          def self.gem_name
            'opensearch-ruby'
          end

          def self.version
            Gem.loaded_specs['opensearch-ruby'] \
              && Gem.loaded_specs['opensearch-ruby'].version
          end

          def self.loaded?
            !defined?(::OpenSearch::Transport).nil?
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
