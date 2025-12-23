# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that `let` is `RuboCop::Config.new` with no arguments.
      #
      # @example
      #   # bad
      #   RSpec.describe RuboCop::Cop::Department::Foo, :config do
      #     let(:config) { RuboCop::Config.new }
      #   end
      #
      #   # good
      #   RSpec.describe RuboCop::Cop::Department::Foo, :config do
      #   end
      #
      #   RSpec.describe RuboCop::Cop::Department::Foo, :config do
      #     let(:config) { RuboCop::Config.new(argument) }
      #   end
      #
      class RedundantLetRuboCopConfigNew < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove `let` that is `RuboCop::Config.new` with no arguments%<additional_message>s.'

        # @!method let_rubocop_config_new?(node)
        def_node_matcher :let_rubocop_config_new?, <<~PATTERN
          (block
            (send nil? :let
              (sym :config))
            (args)
            {
              (send
                (const
                  (const nil? :RuboCop) :Config) :new)
              (send
                (const
                  (const nil? :RuboCop) :Config) :new
                    (hash (pair (send (send (send nil? :described_class) :badge) :to_s)
                      (send nil? :cop_config))))
            }
          )
        PATTERN

        def on_block(node)
          return unless let_rubocop_config_new?(node)

          describe = find_describe_method_node(node)

          unless (exist_config = describe.last_argument.source == ':config')
            additional_message = ' and specify `:config` in `describe`'
          end

          message = format(MSG, additional_message: additional_message)

          add_offense(node, message: message) do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))

            corrector.insert_after(describe.last_argument, ', :config') unless exist_config
          end
        end

        private

        def find_describe_method_node(block_node)
          block_node.ancestors.find { |node| node.block_type? && node.method?(:describe) }.send_node
        end
      end
    end
  end
end
