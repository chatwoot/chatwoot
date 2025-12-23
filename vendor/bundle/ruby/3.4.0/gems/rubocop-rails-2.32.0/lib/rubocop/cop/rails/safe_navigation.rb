# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Converts usages of `try!` to `&.`. It can also be configured
      # to convert `try`. It will convert code to use safe navigation
      # if the target Ruby version is set to 2.3+
      #
      # @example ConvertTry: false (default)
      #   # bad
      #   foo.try!(:bar)
      #   foo.try!(:bar, baz)
      #   foo.try!(:bar) { |e| e.baz }
      #
      #   foo.try!(:[], 0)
      #
      #   # good
      #   foo.try(:bar)
      #   foo.try(:bar, baz)
      #   foo.try(:bar) { |e| e.baz }
      #
      #   foo&.bar
      #   foo&.bar(baz)
      #   foo&.bar { |e| e.baz }
      #
      # @example ConvertTry: true
      #   # bad
      #   foo.try!(:bar)
      #   foo.try!(:bar, baz)
      #   foo.try!(:bar) { |e| e.baz }
      #   foo.try(:bar)
      #   foo.try(:bar, baz)
      #   foo.try(:bar) { |e| e.baz }
      #
      #   # good
      #   foo&.bar
      #   foo&.bar(baz)
      #   foo&.bar { |e| e.baz }
      class SafeNavigation < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.3

        MSG = 'Use safe navigation (`&.`) instead of `%<try>s`.'
        RESTRICT_ON_SEND = %i[try try!].freeze

        def_node_matcher :try_call, <<~PATTERN
          (send _ ${:try :try!} $_ ...)
        PATTERN

        def self.autocorrect_incompatible_with
          [Style::RedundantSelf]
        end

        def on_send(node)
          try_call(node) do |try_method, dispatch|
            return if try_method == :try && !cop_config['ConvertTry']
            return unless dispatch.sym_type? && dispatch.value.match?(/\w+[=!?]?/)

            add_offense(node, message: format(MSG, try: try_method)) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        private

        def autocorrect(corrector, node)
          method_node, *params = *node.arguments
          method = method_node.source[1..]

          range = if node.receiver
                    range_between(node.loc.dot.begin_pos, node.source_range.end_pos)
                  else
                    corrector.insert_before(node, 'self')
                    node
                  end

          corrector.replace(range, replacement(method, params))
        end

        def replacement(method, params)
          new_params = params.map(&:source).join(', ')

          if method.end_with?('=')
            "&.#{method[0...-1]} = #{new_params}"
          elsif params.empty?
            "&.#{method}"
          else
            "&.#{method}(#{new_params})"
          end
        end
      end
    end
  end
end
