# frozen_string_literal: true

require 'yaml'

module RuboCop
  module RSpec
    # Builds a YAML config file from two config hashes
    class ConfigFormatter
      EXTENSION_ROOT_DEPARTMENT = %r{^RSpec/}.freeze
      COP_DOC_BASE_URL = 'https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/'

      def initialize(config, descriptions)
        @config       = config
        @descriptions = descriptions
      end

      def dump
        YAML.dump(unified_config)
          .gsub(%r{^\w+/}, "\n\\0")   # Add an extra newline before each cop.
          .gsub(/^(\s+)- /, '\1  - ') # Add 2 spaces before each array element.
          .gsub('"~"', '~')           # Don't quote tilde, YAML's null value.
      end

      private

      def unified_config
        cops.each_with_object(config.dup) do |cop, unified|
          replace_nil(unified[cop])
          unified[cop].merge!(descriptions.fetch(cop))
          unified[cop]['Reference'] = reference(cop)
        end
      end

      def cops
        (descriptions.keys | config.keys).grep(EXTENSION_ROOT_DEPARTMENT)
      end

      def replace_nil(config)
        config.each do |key, value|
          config[key] = '~' if value.nil?
        end
      end

      def reference(cop)
        COP_DOC_BASE_URL + cop
      end

      attr_reader :config, :descriptions
    end
  end
end
