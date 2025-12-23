# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of the `read_attribute` or `write_attribute`
      # methods and recommends square brackets instead.
      #
      # If an attribute is missing from the instance (for example, when
      # initialized by a partial `select`) then `read_attribute`
      # will return nil, but square brackets will raise
      # an `ActiveModel::MissingAttributeError`.
      #
      # Explicitly raising an error in this situation is preferable, and that
      # is why rubocop recommends using square brackets.
      #
      # @example
      #
      #   # bad
      #   x = read_attribute(:attr)
      #   write_attribute(:attr, val)
      #
      #   # good
      #   x = self[:attr]
      #   self[:attr] = val
      #
      # When called from within a method with the same name as the attribute,
      # `read_attribute` and `write_attribute` must be used to prevent an
      # infinite loop:
      #
      # @example
      #
      #   # good
      #   def foo
      #     bar || read_attribute(:foo)
      #   end
      class ReadWriteAttribute < Base
        extend AutoCorrector

        MSG = 'Prefer `%<prefer>s`.'
        RESTRICT_ON_SEND = %i[read_attribute write_attribute].freeze

        def_node_matcher :read_write_attribute?, <<~PATTERN
          {
            (send nil? :read_attribute _)
            (send nil? :write_attribute _ _)
          }
        PATTERN

        def on_send(node)
          return unless read_write_attribute?(node)
          return if within_shadowing_method?(node)

          add_offense(node, message: build_message(node)) do |corrector|
            corrector.replace(node, node_replacement(node))
          end
        end

        private

        def within_shadowing_method?(node)
          first_arg = node.first_argument
          return false unless first_arg.respond_to?(:value)

          enclosing_method = node.each_ancestor(:def).first
          return false unless enclosing_method

          shadowing_method_name = first_arg.value.to_s
          shadowing_method_name << '=' if node.method?(:write_attribute)
          enclosing_method.method?(shadowing_method_name)
        end

        def build_message(node)
          if node.single_line?
            single_line_message(node)
          else
            multi_line_message(node)
          end
        end

        def single_line_message(node)
          format(MSG, prefer: node_replacement(node))
        end

        def multi_line_message(node)
          if node.method?(:read_attribute)
            format(MSG, prefer: 'self[:attr]')
          else
            format(MSG, prefer: 'self[:attr] = val')
          end
        end

        def node_replacement(node)
          case node.method_name
          when :read_attribute
            read_attribute_replacement(node)
          when :write_attribute
            write_attribute_replacement(node)
          end
        end

        def read_attribute_replacement(node)
          "self[#{node.first_argument.source}]"
        end

        def write_attribute_replacement(node)
          "self[#{node.first_argument.source}] = #{node.last_argument.source}"
        end
      end
    end
  end
end
