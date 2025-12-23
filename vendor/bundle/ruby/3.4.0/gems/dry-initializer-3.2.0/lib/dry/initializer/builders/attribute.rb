# frozen_string_literal: true

module Dry
  module Initializer
    module Builders
      # @private
      class Attribute
        def self.[](definition)
          new(definition).call
        end

        def call
          lines.compact
        end

        private

        def initialize(definition)
          @definition = definition
          @option     = definition.option
          @type       = definition.type
          @optional   = definition.optional
          @default    = definition.default
          @source     = definition.source
          @ivar       = definition.ivar
          @null       = definition.null ? "Dry::Initializer::UNDEFINED" : "nil"
          @opts       = "__dry_initializer_options__"
          @congif     = "__dry_initializer_config__"
          @item       = "__dry_initializer_definition__"
          @val        = @option ? "__dry_initializer_value__" : @source
        end

        def lines
          [
            "",
            definition_line,
            reader_line,
            default_line,
            coercion_line,
            assignment_line
          ]
        end

        def reader_line
          return unless @option

          @optional ? optional_reader : required_reader
        end

        def optional_reader
          "#{@val} = #{@opts}.fetch(:'#{@source}', #{@null})"
        end

        def required_reader
          "#{@val} = #{@opts}.fetch(:'#{@source}')" \
            " { raise KeyError, \"\#{self.class}: #{@definition} is required\" }"
        end

        def definition_line
          return unless @type || @default

          "#{@item} = __dry_initializer_config__.definitions[:'#{@source}']"
        end

        def default_line
          return unless @default

          "#{@val} = instance_exec(&#{@item}.default) if #{@null} == #{@val}"
        end

        def coercion_line
          return unless @type

          arity = @type.is_a?(Proc) ? @type.arity : @type.method(:call).arity

          if arity.equal?(1) || arity.negative?
            "#{@val} = #{@item}.type.call(#{@val}) unless #{@null} == #{@val}"
          else
            "#{@val} = #{@item}.type.call(#{@val}, self) unless #{@null} == #{@val}"
          end
        end

        def assignment_line
          "#{@ivar} = #{@val}" \
            " unless #{@null} == #{@val} && instance_variable_defined?(:#{@ivar})"
        end
      end
    end
  end
end
