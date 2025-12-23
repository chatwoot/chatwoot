# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Check for usages of not (`not` or `!`) called on a method
      # when an inverse of that method can be used instead.
      #
      # Methods that can be inverted by a not (`not` or `!`) should be defined
      # in `InverseMethods`.
      #
      # Methods that are inverted by inverting the return
      # of the block that is passed to the method should be defined in
      # `InverseBlocks`.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the method
      #   and its inverse method are both defined on receiver, and also are
      #   actually inverse of each other.
      #
      # @example
      #   # bad
      #   !foo.none?
      #   !foo.any? { |f| f.even? }
      #   !foo.blank?
      #   !(foo == bar)
      #   foo.select { |f| !f.even? }
      #   foo.reject { |f| f != 7 }
      #
      #   # good
      #   foo.none?
      #   foo.blank?
      #   foo.any? { |f| f.even? }
      #   foo != bar
      #   foo == bar
      #   !!('foo' =~ /^\w+$/)
      #   !(foo.class < Numeric) # Checking class hierarchy is allowed
      #   # Blocks with guard clauses are ignored:
      #   foo.select do |f|
      #     next if f.zero?
      #     f != 1
      #   end
      class InverseMethods < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<inverse>s` instead of inverting `%<method>s`.'
        CLASS_COMPARISON_METHODS = %i[<= >= < >].freeze
        SAFE_NAVIGATION_INCOMPATIBLE_METHODS = (CLASS_COMPARISON_METHODS + %i[any? none?]).freeze
        EQUALITY_METHODS = %i[== != =~ !~ <= >= < >].freeze
        NEGATED_EQUALITY_METHODS = %i[!= !~].freeze
        CAMEL_CASE = /[A-Z]+[a-z]+/.freeze

        RESTRICT_ON_SEND = [:!].freeze

        def self.autocorrect_incompatible_with
          [Style::Not, Style::SymbolProc]
        end

        # @!method inverse_candidate?(node)
        def_node_matcher :inverse_candidate?, <<~PATTERN
          {
            (send $(call $(...) $_ $...) :!)
            (send (any_block $(call $(...) $_) $...) :!)
            (send (begin $(call $(...) $_ $...)) :!)
          }
        PATTERN

        # @!method inverse_block?(node)
        def_node_matcher :inverse_block?, <<~PATTERN
          (any_block $(call (...) $_) ... { $(call ... :!)
                                            $(send (...) {:!= :!~} ...)
                                            (begin ... $(call ... :!))
                                            (begin ... $(send (...) {:!= :!~} ...))
                                          })
        PATTERN

        def on_send(node)
          inverse_candidate?(node) do |method_call, lhs, method, rhs|
            return unless inverse_methods.key?(method)
            return if negated?(node) || safe_navigation_incompatible?(method_call)
            return if part_of_ignored_node?(node)
            return if possible_class_hierarchy_check?(lhs, rhs, method)

            add_offense(node, message: message(method, inverse_methods[method])) do |corrector|
              correct_inverse_method(corrector, node)
            end
          end
        end
        alias on_csend on_send

        def on_block(node)
          inverse_block?(node) do |_method_call, method, block|
            return unless inverse_blocks.key?(method)
            return if negated?(node) && negated?(node.parent)
            return if node.each_node(:next).any?

            # Inverse method offenses inside of the block of an inverse method
            # offense, such as `y.reject { |key, _value| !(key =~ /c\d/) }`,
            # can cause autocorrection to apply improper corrections.
            ignore_node(block)
            add_offense(node, message: message(method, inverse_blocks[method])) do |corrector|
              correct_inverse_block(corrector, node)
            end
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def correct_inverse_method(corrector, node)
          method_call, _lhs, method, _rhs = inverse_candidate?(node)
          return unless method_call && method

          corrector.remove(not_to_receiver(node, method_call))
          corrector.replace(method_call.loc.selector, inverse_methods[method].to_s)
          remove_end_parenthesis(corrector, node, method, method_call)
        end

        def correct_inverse_block(corrector, node)
          method_call, method, block = inverse_block?(node)

          corrector.replace(method_call.loc.selector, inverse_blocks[method].to_s)
          correct_inverse_selector(block, corrector)
        end

        def correct_inverse_selector(block, corrector)
          selector_loc = block.loc.selector
          selector = selector_loc.source

          if NEGATED_EQUALITY_METHODS.include?(selector.to_sym)
            selector[0] = '='
            corrector.replace(selector_loc, selector)
          else
            if block.loc.dot
              range = dot_range(block.loc)
              corrector.remove(range)
            end

            corrector.remove(selector_loc)
          end
        end

        def inverse_methods
          @inverse_methods ||= cop_config['InverseMethods']
                               .merge(cop_config['InverseMethods'].invert)
        end

        def inverse_blocks
          @inverse_blocks ||= cop_config['InverseBlocks'].merge(cop_config['InverseBlocks'].invert)
        end

        def negated?(node)
          node.parent.respond_to?(:method?) && node.parent.method?(:!)
        end

        def not_to_receiver(node, method_call)
          node.loc.selector.begin.join(method_call.source_range.begin)
        end

        def end_parentheses(node, method_call)
          method_call.source_range.end.join(node.source_range.end)
        end

        def safe_navigation_incompatible?(node)
          return false unless node.csend_type?

          SAFE_NAVIGATION_INCOMPATIBLE_METHODS.include?(node.method_name)
        end

        # When comparing classes, `!(Integer < Numeric)` is not the same as
        # `Integer > Numeric`.
        def possible_class_hierarchy_check?(lhs, rhs, method)
          CLASS_COMPARISON_METHODS.include?(method) &&
            (camel_case_constant?(lhs) || (rhs.size == 1 && camel_case_constant?(rhs.first)))
        end

        def camel_case_constant?(node)
          node.const_type? && CAMEL_CASE.match?(node.source)
        end

        def dot_range(loc)
          range_between(loc.dot.begin_pos, loc.expression.end_pos)
        end

        def remove_end_parenthesis(corrector, node, method, method_call)
          return unless EQUALITY_METHODS.include?(method) || method_call.parent.begin_type?

          corrector.remove(end_parentheses(node, method_call))
        end

        def message(method, inverse)
          format(MSG, method: method, inverse: inverse)
        end
      end
    end
  end
end
