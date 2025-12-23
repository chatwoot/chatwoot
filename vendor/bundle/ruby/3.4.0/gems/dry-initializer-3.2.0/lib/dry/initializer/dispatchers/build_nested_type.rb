# frozen_string_literal: true

# Prepare nested data type from a block
#
# @example
#   option :foo do
#     option :bar
#     option :qux
#   end
#
module Dry
  module Initializer
    module Dispatchers
      module BuildNestedType
        extend self

        # rubocop: disable Metrics/ParameterLists
        def call(parent:, source:, target:, type: nil, block: nil, **options)
          check_certainty!(source, type, block)
          check_name!(target, block)
          type ||= build_nested_type(parent, target, block)
          {parent:, source:, target:, type:, **options}
        end
        # rubocop: enable Metrics/ParameterLists

        private

        def check_certainty!(source, type, block)
          return unless block
          return unless type

          raise ArgumentError, <<~MESSAGE
            You should define coercer of values of argument '#{source}'
            either though the parameter/option, or via nested block, but not the both.
          MESSAGE
        end

        def check_name!(name, block)
          return unless block
          return unless name[/^_|__|_$/]

          raise ArgumentError, <<~MESSAGE
            The name of the argument '#{name}' cannot be used for nested struct.
            A proper name can use underscores _ to divide alphanumeric parts only.
          MESSAGE
        end

        def build_nested_type(parent, name, block)
          return unless block

          klass_name = full_name(parent, name)
          build_struct(klass_name, block)
        end

        def full_name(parent, name)
          "::#{parent.name}::#{name.to_s.split("_").compact.map(&:capitalize).join}"
        end

        def build_struct(klass_name, block)
          # rubocop: disable Security/Eval
          eval <<~RUBY, TOPLEVEL_BINDING, __FILE__, __LINE__ + 1
            class #{klass_name} < Dry::Initializer::Struct
            end
          RUBY
          # rubocop: enable Style/DocumentDynamicEvalDefinition
          # rubocop: enable Security/Eval
          const_get(klass_name).tap { _1.class_eval(&block) }
        end
      end
    end
  end
end
