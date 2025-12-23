# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for code that can be written with simpler conditionals
      # using `Object#present?` defined by Active Support.
      #
      # Interaction with `Style/UnlessElse`:
      # The configuration of `NotBlank` will not produce an offense in the
      # context of `unless else` if `Style/UnlessElse` is enabled. This is
      # to prevent interference between the autocorrection of the two cops.
      #
      # @example NotNilAndNotEmpty: true (default)
      #   # Converts usages of `!nil? && !empty?` to `present?`
      #
      #   # bad
      #   !foo.nil? && !foo.empty?
      #
      #   # bad
      #   foo != nil && !foo.empty?
      #
      #   # good
      #   foo.present?
      #
      # @example NotBlank: true (default)
      #   # Converts usages of `!blank?` to `present?`
      #
      #   # bad
      #   !foo.blank?
      #
      #   # bad
      #   not foo.blank?
      #
      #   # good
      #   foo.present?
      #
      # @example UnlessBlank: true (default)
      #   # Converts usages of `unless blank?` to `if present?`
      #
      #   # bad
      #   something unless foo.blank?
      #
      #   # good
      #   something if foo.present?
      class Present < Base
        extend AutoCorrector

        MSG_NOT_BLANK = 'Use `%<prefer>s` instead of `%<current>s`.'
        MSG_EXISTS_AND_NOT_EMPTY = 'Use `%<prefer>s` instead of `%<current>s`.'
        MSG_UNLESS_BLANK = 'Use `if %<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[!].freeze

        def_node_matcher :exists_and_not_empty?, <<~PATTERN
          (and
              {
                (send (send $_ :nil?) :!)
                (send (send $_ :!) :!)
                (send $_ :!= nil)
                $_
              }
              {
                (send (send $_ :empty?) :!)
              }
          )
        PATTERN

        def_node_matcher :not_blank?, '(send (send $_ :blank?) :!)'

        def_node_matcher :unless_blank?, <<~PATTERN
          (:if $(send $_ :blank?) {nil? (...)} ...)
        PATTERN

        def on_send(node)
          return unless cop_config['NotBlank']

          not_blank?(node) do |receiver|
            message = format(MSG_NOT_BLANK, prefer: replacement(receiver), current: node.source)

            add_offense(node, message: message) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        def on_and(node)
          return unless cop_config['NotNilAndNotEmpty']

          exists_and_not_empty?(node) do |var1, var2|
            return unless var1 == var2

            message = format(MSG_EXISTS_AND_NOT_EMPTY, prefer: replacement(var1), current: node.source)

            add_offense(node, message: message) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        def on_or(node)
          exists_and_not_empty?(node) do |var1, var2|
            return unless var1 == var2

            add_offense(node, message: MSG_EXISTS_AND_NOT_EMPTY) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        def on_if(node)
          return unless cop_config['UnlessBlank']
          return unless node.unless?
          return if node.else? && config.cop_enabled?('Style/UnlessElse')

          unless_blank?(node) do |method_call, receiver|
            range = unless_condition(node, method_call)
            msg = format(MSG_UNLESS_BLANK, prefer: replacement(receiver), current: range.source)
            add_offense(range, message: msg) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        def autocorrect(corrector, node)
          method_call, variable1 = unless_blank?(node)

          if method_call
            corrector.replace(node.loc.keyword, 'if')
            range = method_call.source_range
          else
            variable1, _variable2 = exists_and_not_empty?(node) || not_blank?(node)
            range = node.source_range
          end

          corrector.replace(range, replacement(variable1))
        end

        private

        def unless_condition(node, method_call)
          if node.modifier_form?
            node.loc.keyword.join(node.source_range.end)
          else
            node.source_range.begin.join(method_call.source_range)
          end
        end

        def replacement(node)
          node.respond_to?(:source) ? "#{node.source}.present?" : 'present?'
        end
      end
    end
  end
end
