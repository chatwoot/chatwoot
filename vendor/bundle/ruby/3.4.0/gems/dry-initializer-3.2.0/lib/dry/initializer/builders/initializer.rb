# frozen_string_literal: true

module Dry
  module Initializer
    module Builders
      # @private
      class Initializer
        require_relative "signature"
        require_relative "attribute"

        def self.[](config)
          new(config).call
        end

        def call
          lines.flatten.compact.join("\n")
        end

        private

        def initialize(config)
          @config = config
          @definitions = config.definitions.values
        end

        def lines
          [
            undef_line,
            define_line,
            params_lines,
            options_lines,
            end_line
          ]
        end

        def undef_line
          "undef :__dry_initializer_initialize__" \
            " if private_method_defined? :__dry_initializer_initialize__"
        end

        def define_line
          "private def __dry_initializer_initialize__(#{Signature[@config]})"
        end

        def params_lines
          @definitions.reject(&:option).flat_map { Attribute[_1] }.map { "  #{_1}" }
        end

        def options_lines
          @definitions.select(&:option).flat_map { Attribute[_1] }.map { "  #{_1}" }
        end

        def end_line
          "end"
        end
      end
    end
  end
end
