require 'yaml'
require 'erb'
require 'pathname'

module Hashie
  module Extensions
    module Parsers
      class YamlErbParser
        def initialize(file_path, options = {})
          @content = File.read(file_path)
          @file_path = file_path.is_a?(Pathname) ? file_path.to_s : file_path
          @options = options
        end

        def perform
          template = ERB.new(@content)
          template.filename = @file_path
          permitted_classes = @options.fetch(:permitted_classes) { [] }
          permitted_symbols = @options.fetch(:permitted_symbols) { [] }
          aliases = @options.fetch(:aliases) { true }

          yaml_safe_load(template, permitted_classes, permitted_symbols, aliases)
        end

        def self.perform(file_path, options = {})
          new(file_path, options).perform
        end

        private

        if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0') # Ruby 2.6+
          def yaml_safe_load(template, permitted_classes, permitted_symbols, aliases)
            YAML.safe_load(
              template.result,
              permitted_classes: permitted_classes,
              permitted_symbols: permitted_symbols,
              aliases: aliases
            )
          end
        else
          def yaml_safe_load(template, permitted_classes, permitted_symbols, aliases)
            YAML.safe_load(template.result, permitted_classes, permitted_symbols, aliases)
          end
        end
      end
    end
  end
end
