# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks whether some constant value isn't a
      # mutable literal (e.g. array or hash).
      #
      # Strict mode can be used to freeze all constants, rather than
      # just literals.
      # Strict mode is considered an experimental feature. It has not been
      # updated with an exhaustive list of all methods that will produce
      # frozen objects so there is a decent chance of getting some false
      # positives. Luckily, there is no harm in freezing an already
      # frozen object.
      #
      # From Ruby 3.0, this cop honours the magic comment
      # 'shareable_constant_value'. When this magic comment is set to any
      # acceptable value other than none, it will suppress the offenses
      # raised by this cop. It enforces frozen state.
      #
      # NOTE: `Regexp` and `Range` literals are frozen objects since Ruby 3.0.
      #
      # NOTE: From Ruby 3.0, interpolated strings are not frozen when
      # `# frozen-string-literal: true` is used, so this cop enforces explicit
      # freezing for such strings.
      #
      # NOTE: From Ruby 3.0, this cop allows explicit freezing of constants when
      # the `shareable_constant_value` directive is used.
      #
      # @safety
      #   This cop's autocorrection is unsafe since any mutations on objects that
      #   are made frozen will change from being accepted to raising `FrozenError`,
      #   and will need to be manually refactored.
      #
      # @example EnforcedStyle: literals (default)
      #   # bad
      #   CONST = [1, 2, 3]
      #
      #   # good
      #   CONST = [1, 2, 3].freeze
      #
      #   # good
      #   CONST = <<~TESTING.freeze
      #     This is a heredoc
      #   TESTING
      #
      #   # good
      #   CONST = Something.new
      #
      #
      # @example EnforcedStyle: strict
      #   # bad
      #   CONST = Something.new
      #
      #   # bad
      #   CONST = Struct.new do
      #     def foo
      #       puts 1
      #     end
      #   end
      #
      #   # good
      #   CONST = Something.new.freeze
      #
      #   # good
      #   CONST = Struct.new do
      #     def foo
      #       puts 1
      #     end
      #   end.freeze
      #
      # @example
      #   # Magic comment - shareable_constant_value: literal
      #
      #   # bad
      #   CONST = [1, 2, 3]
      #
      #   # good
      #   # shareable_constant_value: literal
      #   CONST = [1, 2, 3]
      #
      class MutableConstant < Base
        # Handles magic comment shareable_constant_value with O(n ^ 2) complexity
        # n - number of lines in the source
        # Iterates over all lines before a CONSTANT
        # until it reaches shareable_constant_value
        module ShareableConstantValue
          module_function

          def recent_shareable_value?(node)
            shareable_constant_comment = magic_comment_in_scope node
            return false if shareable_constant_comment.nil?

            shareable_constant_value = MagicComment.parse(shareable_constant_comment)
                                                   .shareable_constant_value
            shareable_constant_value_enabled? shareable_constant_value
          end

          # Identifies the most recent magic comment with valid shareable constant values
          # that's in scope for this node
          def magic_comment_in_scope(node)
            processed_source_till_node(node).reverse_each.find do |line|
              MagicComment.parse(line).valid_shareable_constant_value?
            end
          end

          private

          def processed_source_till_node(node)
            processed_source.lines[0..(node.last_line - 1)]
          end

          def shareable_constant_value_enabled?(value)
            %w[literal experimental_everything experimental_copy].include? value
          end
        end
        private_constant :ShareableConstantValue

        include ShareableConstantValue
        include FrozenStringLiteral
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Freeze mutable objects assigned to constants.'

        def on_casgn(node)
          if node.expression.nil? # This is only the case for `CONST += ...` or similarg66
            parent = node.parent
            return unless parent.or_asgn_type? # We only care about `CONST ||= ...`

            on_assignment(parent.children.last)
          else
            on_assignment(node.expression)
          end
        end

        private

        def on_assignment(value)
          if style == :strict
            strict_check(value)
          else
            check(value)
          end
        end

        def strict_check(value)
          return if immutable_literal?(value)
          return if operation_produces_immutable_object?(value)
          return if frozen_string_literal?(value)
          return if shareable_constant_value?(value)

          add_offense(value) { |corrector| autocorrect(corrector, value) }
        end

        def check(value)
          range_enclosed_in_parentheses = range_enclosed_in_parentheses?(value)
          return unless mutable_literal?(value) ||
                        (target_ruby_version <= 2.7 && range_enclosed_in_parentheses)

          return if frozen_string_literal?(value)
          return if shareable_constant_value?(value)

          add_offense(value) { |corrector| autocorrect(corrector, value) }
        end

        def autocorrect(corrector, node)
          expr = node.source_range

          splat_value = splat_value(node)
          if splat_value
            correct_splat_expansion(corrector, expr, splat_value)
          elsif node.array_type? && !node.bracketed?
            corrector.wrap(expr, '[', ']')
          elsif requires_parentheses?(node)
            corrector.wrap(expr, '(', ')')
          end

          corrector.insert_after(expr, '.freeze')
        end

        def mutable_literal?(value)
          return false if frozen_regexp_or_range_literals?(value)

          value.mutable_literal?
        end

        def immutable_literal?(node)
          frozen_regexp_or_range_literals?(node) || node.immutable_literal?
        end

        def shareable_constant_value?(node)
          return false if target_ruby_version < 3.0

          recent_shareable_value? node
        end

        def frozen_regexp_or_range_literals?(node)
          target_ruby_version >= 3.0 && node.type?(:regexp, :range)
        end

        def requires_parentheses?(node)
          node.range_type? || (node.send_type? && node.loc.dot.nil?)
        end

        def correct_splat_expansion(corrector, expr, splat_value)
          if range_enclosed_in_parentheses?(splat_value)
            corrector.replace(expr, "#{splat_value.source}.to_a")
          else
            corrector.replace(expr, "(#{splat_value.source}).to_a")
          end
        end

        # @!method splat_value(node)
        def_node_matcher :splat_value, <<~PATTERN
          (array (splat $_))
        PATTERN

        # Some of these patterns may not actually return an immutable object,
        # but we want to consider them immutable for this cop.
        # @!method operation_produces_immutable_object?(node)
        def_node_matcher :operation_produces_immutable_object?, <<~PATTERN
          {
            (const _ _)
            (send (const {nil? cbase} :Struct) :new ...)
            (block (send (const {nil? cbase} :Struct) :new ...) ...)
            (send _ :freeze)
            (send {float int} {:+ :- :* :** :/ :% :<<} _)
            (send _ {:+ :- :* :** :/ :%} {float int})
            (send _ {:== :=== :!= :<= :>= :< :>} _)
            (send (const {nil? cbase} :ENV) :[] _)
            (or (send (const {nil? cbase} :ENV) :[] _) _)
            (send _ {:count :length :size} ...)
            (block (send _ {:count :length :size} ...) ...)
          }
        PATTERN

        # @!method range_enclosed_in_parentheses?(node)
        def_node_matcher :range_enclosed_in_parentheses?, <<~PATTERN
          (begin (range _ _))
        PATTERN
      end
    end
  end
end
