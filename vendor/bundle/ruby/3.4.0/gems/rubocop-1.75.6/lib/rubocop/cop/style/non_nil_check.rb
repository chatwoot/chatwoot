# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for non-nil checks, which are usually redundant.
      #
      # With `IncludeSemanticChanges` set to `false` by default, this cop
      # does not report offenses for `!x.nil?` and does no changes that might
      # change behavior.
      # Also `IncludeSemanticChanges` set to `false` with `EnforcedStyle: comparison` of
      # `Style/NilComparison` cop, this cop does not report offenses for `x != nil` and
      # does no changes to `!x.nil?` style.
      #
      # With `IncludeSemanticChanges` set to `true`, this cop reports offenses
      # for `!x.nil?` and autocorrects that and `x != nil` to solely `x`, which
      # is *usually* OK, but might change behavior.
      #
      # @example
      #   # bad
      #   if x != nil
      #   end
      #
      #   # good
      #   if x
      #   end
      #
      #   # Non-nil checks are allowed if they are the final nodes of predicate.
      #   # good
      #   def signed_in?
      #     !current_user.nil?
      #   end
      #
      # @example IncludeSemanticChanges: false (default)
      #   # good
      #   if !x.nil?
      #   end
      #
      # @example IncludeSemanticChanges: true
      #   # bad
      #   if !x.nil?
      #   end
      #
      class NonNilCheck < Base
        extend AutoCorrector

        MSG_FOR_REPLACEMENT = 'Prefer `%<prefer>s` over `%<current>s`.'
        MSG_FOR_REDUNDANCY = 'Explicit non-nil checks are usually redundant.'

        RESTRICT_ON_SEND = %i[!= nil? !].freeze

        # @!method not_equal_to_nil?(node)
        def_node_matcher :not_equal_to_nil?, '(send _ :!= nil)'

        # @!method unless_check?(node)
        def_node_matcher :unless_check?, '(if (send _ :nil?) ...)'

        # @!method nil_check?(node)
        def_node_matcher :nil_check?, '(send _ :nil?)'

        # @!method not_and_nil_check?(node)
        def_node_matcher :not_and_nil_check?, '(send (send _ :nil?) :!)'

        def on_send(node)
          return if ignored_node?(node) ||
                    (!include_semantic_changes? && nil_comparison_style == 'comparison')
          return unless register_offense?(node)

          message = message(node)
          add_offense(node, message: message) { |corrector| autocorrect(corrector, node) }
        end

        def on_def(node)
          body = node.body

          return unless node.predicate_method? && body

          if body.begin_type?
            ignore_node(body.children.last)
          else
            ignore_node(body)
          end
        end
        alias on_defs on_def

        private

        def register_offense?(node)
          not_equal_to_nil?(node) ||
            (include_semantic_changes? && (not_and_nil_check?(node) || unless_and_nil_check?(node)))
        end

        def autocorrect(corrector, node)
          case node.method_name
          when :!=
            autocorrect_comparison(corrector, node)
          when :!
            autocorrect_non_nil(corrector, node, node.receiver)
          when :nil?
            autocorrect_unless_nil(corrector, node, node.receiver)
          end
        end

        def unless_and_nil_check?(send_node)
          parent = send_node.parent

          nil_check?(send_node) && unless_check?(parent) && !parent.ternary? && parent.unless?
        end

        def message(node)
          if node.method?(:!=) && !include_semantic_changes?
            prefer = "!#{node.receiver.source}.nil?"
            format(MSG_FOR_REPLACEMENT, prefer: prefer, current: node.source)
          else
            MSG_FOR_REDUNDANCY
          end
        end

        def include_semantic_changes?
          cop_config['IncludeSemanticChanges']
        end

        def autocorrect_comparison(corrector, node)
          expr = node.source

          new_code = if include_semantic_changes?
                       expr.sub(/\s*!=\s*nil/, '')
                     else
                       expr.sub(/^(\S*)\s*!=\s*nil/, '!\1.nil?')
                     end

          return if expr == new_code

          corrector.replace(node, new_code)
        end

        def autocorrect_non_nil(corrector, node, inner_node)
          if inner_node.receiver
            corrector.replace(node, inner_node.receiver.source)
          else
            corrector.replace(node, 'self')
          end
        end

        def autocorrect_unless_nil(corrector, node, receiver)
          corrector.replace(node.parent.loc.keyword, 'if')
          corrector.replace(node, receiver.source)
        end

        def nil_comparison_style
          nil_comparison_conf = config.for_cop('Style/NilComparison')

          nil_comparison_conf['Enabled'] && nil_comparison_conf['EnforcedStyle']
        end
      end
    end
  end
end
