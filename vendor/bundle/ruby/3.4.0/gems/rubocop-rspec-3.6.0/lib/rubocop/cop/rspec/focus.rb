# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if examples are focused.
      #
      # This cop does not support autocorrection in some cases.
      #
      # @example
      #   # bad
      #   describe MyClass, focus: true do
      #   end
      #
      #   describe MyClass, :focus do
      #   end
      #
      #   fdescribe MyClass do
      #   end
      #
      #   # good
      #   describe MyClass do
      #   end
      #
      #   # bad
      #   fdescribe 'test' do; end
      #
      #   # good
      #   describe 'test' do; end
      #
      #   # bad
      #   shared_examples 'test', focus: true do; end
      #
      #   # good
      #   shared_examples 'test' do; end
      #
      #   # bad
      #   shared_context 'test', focus: true do; end
      #
      #   # good
      #   shared_context 'test' do; end
      #
      #   # bad (does not support autocorrection)
      #   focus 'test' do; end
      #
      class Focus < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Focused spec found.'

        # @!method focusable_selector?(node)
        def_node_matcher :focusable_selector?, <<~PATTERN
          {
            #ExampleGroups.regular
            #ExampleGroups.skipped
            #Examples.regular
            #Examples.skipped
            #Examples.pending
            #SharedGroups.all
          }
        PATTERN

        # @!method metadata(node)
        def_node_matcher :metadata, <<~PATTERN
          {(send #rspec? #focusable_selector? <$(sym :focus) ...>)
           (send #rspec? #focusable_selector? ... (hash <$(pair (sym :focus) true) ...>))}
        PATTERN

        # @!method focused_block?(node)
        def_node_matcher :focused_block?, <<~PATTERN
          (send #rspec? {#ExampleGroups.focused #Examples.focused} ...)
        PATTERN

        def on_send(node)
          return if node.chained? || node.each_ancestor(:any_def).any?

          if focused_block?(node)
            on_focused_block(node)
          else
            metadata(node) do |focus|
              on_metadata(focus)
            end
          end
        end

        private

        def on_focused_block(node)
          add_offense(node) do |corrector|
            correct_send(corrector, node)
          end
        end

        def on_metadata(node)
          add_offense(node) do |corrector|
            corrector.remove(with_surrounding(node))
          end
        end

        def with_surrounding(focus)
          range_with_space =
            range_with_surrounding_space(focus.source_range, side: :left)

          range_with_surrounding_comma(range_with_space, :left)
        end

        def correct_send(corrector, focus)
          range = focus.loc.selector
          unfocused = focus.method_name.to_s.sub(/^f/, '')
          unless Examples.regular(unfocused) || ExampleGroups.regular(unfocused)
            return
          end

          corrector.replace(range,
                            range.source.sub(focus.method_name.to_s, unfocused))
        end
      end
    end
  end
end
