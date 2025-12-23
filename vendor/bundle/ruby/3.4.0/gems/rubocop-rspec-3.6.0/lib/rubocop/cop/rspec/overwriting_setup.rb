# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is a let/subject that overwrites an existing one.
      #
      # @example
      #   # bad
      #   let(:foo) { bar }
      #   let(:foo) { baz }
      #
      #   subject(:foo) { bar }
      #   let(:foo) { baz }
      #
      #   let(:foo) { bar }
      #   let!(:foo) { baz }
      #
      #   # good
      #   subject(:test) { something }
      #   let(:foo) { bar }
      #   let(:baz) { baz }
      #   let!(:other) { other }
      #
      class OverwritingSetup < Base
        MSG = '`%<name>s` is already defined.'

        # @!method setup?(node)
        def_node_matcher :setup?, <<~PATTERN
          (block (send nil? {#Helpers.all #Subjects.all} ...) ...)
        PATTERN

        # @!method first_argument_name(node)
        def_node_matcher :first_argument_name, '(send _ _ ({str sym} $_))'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group_with_body?(node)

          find_duplicates(node.body) do |duplicate, name|
            add_offense(
              duplicate,
              message: format(MSG, name: name)
            )
          end
        end

        private

        def find_duplicates(node)
          setup_expressions = Set.new
          node.each_child_node(:block) do |child|
            next unless common_setup?(child)

            name = if child.send_node.arguments?
                     first_argument_name(child.send_node).to_sym
                   else
                     :subject
                   end

            yield child, name unless setup_expressions.add?(name)
          end
        end

        def common_setup?(node)
          return false unless setup?(node)

          # Search only for setup with basic_literal arguments (e.g. :sym, :str)
          # or no arguments at all.
          node.send_node.arguments.all?(&:basic_literal?)
        end
      end
    end
  end
end
