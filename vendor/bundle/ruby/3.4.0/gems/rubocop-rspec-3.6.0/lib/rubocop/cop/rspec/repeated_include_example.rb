# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for repeated include of shared examples.
      #
      # @example
      #   # bad
      #   describe 'foo' do
      #     include_examples 'cool stuff'
      #     include_examples 'cool stuff'
      #   end
      #
      #   # bad
      #   describe 'foo' do
      #     it_behaves_like 'a cool', 'thing'
      #     it_behaves_like 'a cool', 'thing'
      #   end
      #
      #   # bad
      #   context 'foo' do
      #     it_should_behave_like 'a duck'
      #     it_should_behave_like 'a duck'
      #   end
      #
      #   # good
      #   describe 'foo' do
      #     include_examples 'cool stuff'
      #   end
      #
      #   describe 'bar' do
      #     include_examples 'cool stuff'
      #   end
      #
      #   # good
      #   describe 'foo' do
      #     it_behaves_like 'a cool', 'thing'
      #     it_behaves_like 'a cool', 'person'
      #   end
      #
      #   # good
      #   context 'foo' do
      #     it_should_behave_like 'a duck'
      #     it_should_behave_like 'a goose'
      #   end
      #
      class RepeatedIncludeExample < Base
        MSG = 'Repeated include of shared_examples %<name>s ' \
              'on line(s) %<repeat>s'

        # @!method several_include_examples?(node)
        def_node_matcher :several_include_examples?, <<~PATTERN
          (begin <#include_examples? #include_examples? ...>)
        PATTERN

        # @!method include_examples?(node)
        def_node_matcher :include_examples?,
                         '(send nil? #Includes.examples ...)'

        # @!method shared_examples_name(node)
        def_node_matcher :shared_examples_name,
                         '(send nil? #Includes.examples $_name ...)'

        def on_begin(node)
          return unless several_include_examples?(node)

          repeated_include_examples(node).each do |item, repeats|
            add_offense(item, message: message(item, repeats))
          end
        end

        private

        def repeated_include_examples(node)
          node
            .children
            .select { |child| literal_include_examples?(child) }
            .group_by { |child| signature_keys(child) }
            .values
            .reject(&:one?)
            .flat_map { |items| add_repeated_lines(items) }
        end

        def literal_include_examples?(node)
          include_examples?(node) &&
            node.arguments.all?(&:recursive_literal_or_const?)
        end

        def add_repeated_lines(items)
          repeated_lines = items.map(&:first_line)
          items.map { |item| [item, repeated_lines - [item.first_line]] }
        end

        def signature_keys(item)
          item.arguments
        end

        def message(item, repeats)
          format(MSG, name: shared_examples_name(item).source, repeat: repeats)
        end
      end
    end
  end
end
