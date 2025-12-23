# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that the second argument to `describe` specifies a method.
      #
      # @example
      #   # bad
      #   describe MyClass, 'do something' do
      #   end
      #
      #   # good
      #   describe MyClass, '#my_instance_method' do
      #   end
      #
      #   describe MyClass, '.my_class_method' do
      #   end
      #
      class DescribeMethod < Base
        include TopLevelGroup

        MSG = 'The second argument to describe should be the method ' \
              "being tested. '#instance' or '.class'."

        # @!method second_string_literal_argument(node)
        def_node_matcher :second_string_literal_argument, <<~PATTERN
          (block
            (send #rspec? :describe _first_argument ${str dstr} ...)
          ...)
        PATTERN

        # @!method method_name?(node)
        def_node_matcher :method_name?, <<~PATTERN
          {(str #method_name_prefix?) (dstr (str #method_name_prefix?) ...)}
        PATTERN

        def on_top_level_group(node)
          second_string_literal_argument(node) do |argument|
            add_offense(argument) unless method_name?(argument)
          end
        end

        private

        def method_name_prefix?(description)
          description.start_with?('.', '#')
        end
      end
    end
  end
end
