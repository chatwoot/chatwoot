# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for redundant `subject(:cop) { described_class.new }`.
      #
      # @example
      #   # bad
      #   RSpec.describe RuboCop::Cop::Department::Foo do
      #     subject(:cop) { described_class.new(config) }
      #   end
      #
      #   # good
      #   RSpec.describe RuboCop::Cop::Department::Foo, :config do
      #   end
      #
      class RedundantDescribedClassAsSubject < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove the redundant `subject`%<additional_message>s.'

        # @!method described_class_subject?(node)
        def_node_matcher :described_class_subject?, <<~PATTERN
          (block
            (send nil? :subject
              (sym :cop))
            (args)
            (send
              (send nil? :described_class) :new
              $...))
        PATTERN

        def on_block(node)
          return unless (described_class_arguments = described_class_subject?(node))
          return if described_class_arguments.count >= 2

          describe = find_describe_method_node(node)

          should_append_config = describe && describe.last_argument.source != ':config'
          additional_message = ' and specify `:config` in `describe`' if should_append_config

          message = format(MSG, additional_message: additional_message)

          add_offense(node, message: message) do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))

            corrector.insert_after(describe.last_argument, ', :config') if should_append_config
          end
        end

        private

        def find_describe_method_node(block_node)
          block_node.ancestors.find do |node|
            node.block_type? && node.method?(:describe)
          end&.send_node
        end
      end
    end
  end
end
