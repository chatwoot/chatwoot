# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for redundant safe navigation calls.
      # Use cases where a constant, named in camel case for classes and modules is `nil` are rare,
      # and an offense is not detected when the receiver is a constant. The detection also applies
      # to `self`, and to literal receivers, except for `nil`.
      #
      # For all receivers, the `instance_of?`, `kind_of?`, `is_a?`, `eql?`, `respond_to?`,
      # and `equal?` methods are checked by default.
      # These are customizable with `AllowedMethods` option.
      #
      # The `AllowedMethods` option specifies nil-safe methods,
      # in other words, it is a method that is allowed to skip safe navigation.
      # Note that the `AllowedMethod` option is not an option that specifies methods
      # for which to suppress (allow) this cop's check.
      #
      # In the example below, the safe navigation operator (`&.`) is unnecessary
      # because `NilClass` has methods like `respond_to?` and `is_a?`.
      #
      # @safety
      #   This cop is unsafe, because autocorrection can change the return type of
      #   the expression. An offending expression that previously could return `nil`
      #   will be autocorrected to never return `nil`.
      #
      # @example
      #   # bad
      #   CamelCaseConst&.do_something
      #
      #   # good
      #   CamelCaseConst.do_something
      #
      #   # bad
      #   do_something if attrs&.respond_to?(:[])
      #
      #   # good
      #   do_something if attrs.respond_to?(:[])
      #
      #   # bad
      #   while node&.is_a?(BeginNode)
      #     node = node.parent
      #   end
      #
      #   # good
      #   while node.is_a?(BeginNode)
      #     node = node.parent
      #   end
      #
      #   # good - without `&.` this will always return `true`
      #   foo&.respond_to?(:to_a)
      #
      #   # bad - for `nil`s conversion methods return default values for the type
      #   foo&.to_h || {}
      #   foo&.to_h { |k, v| [k, v] } || {}
      #   foo&.to_a || []
      #   foo&.to_i || 0
      #   foo&.to_f || 0.0
      #   foo&.to_s || ''
      #
      #   # good
      #   foo.to_h
      #   foo.to_h { |k, v| [k, v] }
      #   foo.to_a
      #   foo.to_i
      #   foo.to_f
      #   foo.to_s
      #
      #   # bad
      #   self&.foo
      #
      #   # good
      #   self.foo
      #
      # @example AllowedMethods: [nil_safe_method]
      #   # bad
      #   do_something if attrs&.nil_safe_method(:[])
      #
      #   # good
      #   do_something if attrs.nil_safe_method(:[])
      #   do_something if attrs&.not_nil_safe_method(:[])
      #
      class RedundantSafeNavigation < Base
        include AllowedMethods
        extend AutoCorrector

        MSG = 'Redundant safe navigation detected, use `.` instead.'
        MSG_LITERAL = 'Redundant safe navigation with default literal detected.'

        NIL_SPECIFIC_METHODS = (nil.methods - Object.new.methods).to_set.freeze

        SNAKE_CASE = /\A[[:digit:][:upper:]_]+\z/.freeze

        # @!method respond_to_nil_specific_method?(node)
        def_node_matcher :respond_to_nil_specific_method?, <<~PATTERN
          (csend _ :respond_to? (sym %NIL_SPECIFIC_METHODS))
        PATTERN

        # @!method conversion_with_default?(node)
        def_node_matcher :conversion_with_default?, <<~PATTERN
          {
            (or $(csend _ :to_h) (hash))
            (or (block $(csend _ :to_h) ...) (hash))
            (or $(csend _ :to_a) (array))
            (or $(csend _ :to_i) (int 0))
            (or $(csend _ :to_f) (float 0.0))
            (or $(csend _ :to_s) (str empty?))
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_csend(node)
          unless assume_receiver_instance_exists?(node.receiver)
            return unless check?(node) && allowed_method?(node.method_name)
            return if respond_to_nil_specific_method?(node)
          end

          range = node.loc.dot
          add_offense(range) { |corrector| corrector.replace(range, '.') }
        end

        def on_or(node)
          conversion_with_default?(node) do |send_node|
            range = send_node.loc.dot.begin.join(node.source_range.end)

            add_offense(range, message: MSG_LITERAL) do |corrector|
              corrector.replace(send_node.loc.dot, '.')

              range_with_default = node.lhs.source_range.end.begin.join(node.source_range.end)
              corrector.remove(range_with_default)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def assume_receiver_instance_exists?(receiver)
          return true if receiver.const_type? && !receiver.short_name.match?(SNAKE_CASE)

          receiver.self_type? || (receiver.literal? && !receiver.nil_type?)
        end

        def check?(node)
          parent = node.parent
          return false unless parent

          condition?(parent, node) ||
            parent.operator_keyword? ||
            (parent.send_type? && parent.negation_method?)
        end

        def condition?(parent, node)
          (parent.conditional? || parent.post_condition_loop?) && parent.condition == node
        end
      end
    end
  end
end
