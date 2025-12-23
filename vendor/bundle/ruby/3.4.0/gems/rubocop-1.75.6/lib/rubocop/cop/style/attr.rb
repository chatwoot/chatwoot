# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of Module#attr.
      #
      # @example
      #   # bad - creates a single attribute accessor (deprecated in Ruby 1.9)
      #   attr :something, true
      #   attr :one, :two, :three # behaves as attr_reader
      #
      #   # good
      #   attr_accessor :something
      #   attr_reader :one, :two, :three
      #
      class Attr < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use `attr`. Use `%<replacement>s` instead.'
        RESTRICT_ON_SEND = %i[attr].freeze

        def on_send(node)
          return unless node.command?(:attr) && node.arguments?
          # check only for method definitions in class/module body
          return if allowed_context?(node)

          message = message(node)
          add_offense(node.loc.selector, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def allowed_context?(node)
          return false unless (class_node = node.each_ancestor(:class, :block).first)

          (!class_node.class_type? && !class_eval?(class_node)) || define_attr_method?(class_node)
        end

        def define_attr_method?(node)
          node.each_descendant(:def).any? { |def_node| def_node.method?(:attr) }
        end

        def autocorrect(corrector, node)
          attr_name, setter = *node.arguments

          node_expr = node.source_range
          attr_expr = attr_name.source_range

          remove = range_between(attr_expr.end_pos, node_expr.end_pos) if setter&.boolean_type?

          corrector.replace(node.loc.selector, replacement_method(node))
          corrector.remove(remove) if remove
        end

        def message(node)
          format(MSG, replacement: replacement_method(node))
        end

        def replacement_method(node)
          setter = node.last_argument

          if setter&.boolean_type?
            setter.true_type? ? 'attr_accessor' : 'attr_reader'
          else
            'attr_reader'
          end
        end

        # @!method class_eval?(node)
        def_node_matcher :class_eval?, <<~PATTERN
          (block (send _ {:class_eval :module_eval}) ...)
        PATTERN
      end
    end
  end
end
