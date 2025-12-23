# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      class AggregateExamples < ::RuboCop::Cop::Cop
        # @example `its`
        #
        #   # Supports regular `its` call with an attribute/method name,
        #   # or a chain of methods expressed as a string with dots.
        #
        #   its(:one) { is_expected.to be(true) }
        #   its('two') { is_expected.to be(false) }
        #   its('phone_numbers.size') { is_expected.to be 2 }
        #
        # @example `its` with single-element array argument
        #
        #   # Also supports single-element array argument.
        #
        #   its(['headers']) { is_expected.to include(encoding: 'text') }
        #
        # @example `its` with multi-element array argument is ambiguous
        #
        #   # Does not support `its` with multi-element array argument due to
        #   # an ambiguity. Transformation depends on the type of the subject:
        #   # - a Hash: `hash[element1][element2]...`
        #   # - and arbitrary type: `hash[element1, element2, ...]`
        #   # It is impossible to infer the type to propose a proper correction.
        #
        #   its(['ambiguous', 'elements']) { ... }
        #
        # @example `its` with metadata
        #
        #   its('header', html: true) { is_expected.to include(text: 'hello') }
        #
        module Its
          extend RuboCop::NodePattern::Macros

          private

          # It's impossible to aggregate `its` body as is, it needs to be
          # converted to `expect(subject.something).to ...`
          def new_body(node)
            return super unless its?(node)

            transform_its(node.body, node.send_node.arguments)
          end

          def transform_its(body, arguments)
            argument = arguments.first
            replacement =
              case argument.type
              when :array
                key = argument.values.first
                "expect(subject[#{key.source}])"
              else
                property = argument.value
                "expect(subject.#{property})"
              end
            body.source.gsub(/is_expected|are_expected/, replacement)
          end

          def example_metadata(example)
            return super unless its?(example.send_node)

            # First parameter to `its` is not metadata.
            example.send_node.arguments[1..-1]
          end

          def its?(node)
            node.method_name == :its
          end

          # In addition to base definition, matches examples with:
          #   - no `its` with an multiple-element array argument due to
          #     an ambiguity, when SUT can be a hash, and result will be defined
          #     by calling `[]` on SUT subsequently, e.g. `subject[one][two]`,
          #     or any other type of object implementing `[]`, and then all the
          #     array arguments are passed to `[]`, e.g. `subject[one, two]`.
          def_node_matcher :example_for_autocorrect?, <<-PATTERN
            [
              #super
              !#its_with_multi_element_array_argument?
              !#its_with_send_or_var_argument?
            ]
          PATTERN

          def_node_matcher :its_with_multi_element_array_argument?, <<-PATTERN
            (block (send nil? :its (array _ _ ...)) ...)
          PATTERN

          def_node_matcher :its_with_send_or_var_argument?, <<-PATTERN
            (block (send nil? :its { send lvar ivar cvar gvar const }) ...)
          PATTERN
        end
      end
    end
  end
end
