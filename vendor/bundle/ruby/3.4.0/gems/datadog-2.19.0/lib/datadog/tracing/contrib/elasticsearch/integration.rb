# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Elasticsearch
        # Description of Elasticsearch integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.0.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :elasticsearch, auto_patch: true

          def self.version
            # elastic-transport gem for version >= 8.0.0
            # elasticsearch-transport gem for version < 8.0.0
            Gem.loaded_specs['elastic-transport'] \
              && Gem.loaded_specs['elastic-transport'].version || \
              Gem.loaded_specs['elasticsearch-transport'] \
                && Gem.loaded_specs['elasticsearch-transport'].version
          end

          def self.loaded?
            # Elastic::Transport gem for version >= 8.0.0
            # Elasticsearch::Transport gem for version < 8.0.0
            !defined?(::Elastic::Transport).nil? || !defined?(::Elasticsearch::Transport).nil?
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
