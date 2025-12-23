# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of the case equality operator(===).
      #
      # If `AllowOnConstant` option is enabled, the cop will ignore violations when the receiver of
      # the case equality operator is a constant.

      # If `AllowOnSelfClass` option is enabled, the cop will ignore violations when the receiver of
      # the case equality operator is `self.class`. Note intermediate variables are not accepted.
      #
      # @example
      #   # bad
      #   (1..100) === 7
      #   /something/ === some_string
      #
      #   # good
      #   something.is_a?(Array)
      #   (1..100).include?(7)
      #   /something/.match?(some_string)
      #
      # @example AllowOnConstant: false (default)
      #   # bad
      #   Array === something
      #
      # @example AllowOnConstant: true
      #   # good
      #   Array === something
      #
      # @example AllowOnSelfClass: false (default)
      #   # bad
      #   self.class === something
      #
      # @example AllowOnSelfClass: true
      #   # good
      #   self.class === something
      #
      class CaseEquality < Base
        extend AutoCorrector

        MSG = 'Avoid the use of the case equality operator `===`.'
        RESTRICT_ON_SEND = %i[===].freeze

        # @!method case_equality?(node)
        def_node_matcher :case_equality?, '(send $#offending_receiver? :=== $_)'

        # @!method self_class?(node)
        def_node_matcher :self_class?, '(send (self) :class)'

        def on_send(node)
          case_equality?(node) do |lhs, rhs|
            return if lhs.const_type? && !lhs.module_name?

            add_offense(node.loc.selector) do |corrector|
              replacement = replacement(lhs, rhs)
              corrector.replace(node, replacement) if replacement
            end
          end
        end

        private

        def offending_receiver?(node)
          return false if node&.const_type? && cop_config.fetch('AllowOnConstant', false)
          return false if self_class?(node) && cop_config.fetch('AllowOnSelfClass', false)

          true
        end

        def replacement(lhs, rhs)
          case lhs.type
          when :regexp
            # The automatic correction from `a === b` to `a.match?(b)` needs to
            # consider `Regexp.last_match?`, `$~`, `$1`, and etc.
            # This correction is expected to be supported by `Performance/Regexp` cop.
            # See: https://github.com/rubocop/rubocop-performance/issues/152
            #
            # So here is noop.
          when :begin
            begin_replacement(lhs, rhs)
          when :const
            const_replacement(lhs, rhs)
          when :send
            send_replacement(lhs, rhs)
          end
        end

        def begin_replacement(lhs, rhs)
          return unless lhs.children.first&.range_type?

          "#{lhs.source}.include?(#{rhs.source})"
        end

        def const_replacement(lhs, rhs)
          "#{rhs.source}.is_a?(#{lhs.source})"
        end

        def send_replacement(lhs, rhs)
          return unless self_class?(lhs)

          "#{rhs.source}.is_a?(#{lhs.source})"
        end
      end
    end
  end
end
