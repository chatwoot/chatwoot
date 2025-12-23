# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent verified double reference style.
      #
      # @see https://rspec.info/features/3-12/rspec-mocks/verifying-doubles
      #
      # @safety
      #   This cop is unsafe because the correction requires loading the class.
      #   Loading before stubbing causes RSpec to only allow instance methods
      #   to be stubbed.
      #
      # @example
      #   # bad
      #   let(:foo) do
      #     instance_double('ClassName', method_name: 'returned_value')
      #   end
      #
      #   # good
      #   let(:foo) do
      #     instance_double(ClassName, method_name: 'returned_value')
      #   end
      #
      # @example Reference is any dynamic variable. No enforcement
      #
      #   # good
      #   let(:foo) do
      #     instance_double(@klass, method_name: 'returned_value')
      #   end
      class VerifiedDoubleReference < Base
        extend AutoCorrector

        MSG = 'Use a constant class reference for verified doubles. ' \
              'String references are not verifying unless the class is loaded.'

        RESTRICT_ON_SEND = Set[
          :class_double,
          :class_spy,
          :instance_double,
          :instance_spy,
          :mock_model,
          :object_double,
          :object_spy,
          :stub_model
        ].freeze

        # @!method verified_double(node)
        def_node_matcher :verified_double, <<~PATTERN
          (send
            nil?
            RESTRICT_ON_SEND
            $str
            ...)
        PATTERN

        def on_send(node)
          verified_double(node) do |string_argument_node|
            add_offense(string_argument_node) do |corrector|
              autocorrect(corrector, string_argument_node)
            end
          end
        end

        def autocorrect(corrector, node)
          corrector.replace(node, node.value)
        end
      end
    end
  end
end
