# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of Perl-style regexp match
      # backreferences and their English versions like
      # $1, $2, $&, &+, $MATCH, $PREMATCH, etc.
      #
      # @example
      #   # bad
      #   puts $1
      #
      #   # good
      #   puts Regexp.last_match(1)
      class PerlBackrefs < Base
        extend AutoCorrector

        MESSAGE_FORMAT = 'Prefer `%<preferred_expression>s` over `%<original_expression>s`.'

        def on_back_ref(node)
          on_back_ref_or_gvar_or_nth_ref(node)
        end

        def on_gvar(node)
          on_back_ref_or_gvar_or_nth_ref(node)
        end

        def on_nth_ref(node)
          on_back_ref_or_gvar_or_nth_ref(node)
        end

        private

        # @private
        # @param [RuboCop::AST::Node] node
        # @return [Boolean]
        def derived_from_braceless_interpolation?(node)
          %i[dstr regexp xstr].include?(node.parent&.type)
        end

        # @private
        # @param [RuboCop::AST::Node] node
        # @param [String] preferred_expression
        # @return [String]
        def format_message(node:, preferred_expression:)
          original_expression = original_expression_of(node)
          format(
            MESSAGE_FORMAT,
            original_expression: original_expression,
            preferred_expression: preferred_expression
          )
        end

        # @private
        # @param [RuboCop::AST::Node] node
        # @return [String]
        def original_expression_of(node)
          first = node.to_a.first
          if first.is_a?(::Integer)
            "$#{first}"
          else
            first.to_s
          end
        end

        # @private
        # @param [RuboCop::AST::Node] node
        # @return [String, nil]
        def preferred_expression_to(node)
          first = node.to_a.first
          case first
          when ::Integer
            "Regexp.last_match(#{first})"
          when :$&, :$MATCH
            'Regexp.last_match(0)'
          when :$`, :$PREMATCH
            'Regexp.last_match.pre_match'
          when :$', :$POSTMATCH
            'Regexp.last_match.post_match'
          when :$+, :$LAST_PAREN_MATCH
            'Regexp.last_match(-1)'
          end
        end

        # @private
        # @param [RuboCop::AST::Node] node
        # @return [String, nil]
        def preferred_expression_to_node_with_constant_prefix(node)
          expression = preferred_expression_to(node)
          return unless expression

          "#{constant_prefix(node)}#{expression}"
        end

        # @private
        # @param [RuboCop::AST::Node] node
        # @return [String]
        def constant_prefix(node)
          if node.each_ancestor(:class, :module).any?
            '::'
          else
            ''
          end
        end

        # @private
        # @param [RuboCop::AST::Node] node
        def on_back_ref_or_gvar_or_nth_ref(node)
          preferred_expression = preferred_expression_to_node_with_constant_prefix(node)
          return unless preferred_expression

          add_offense(
            node,
            message: format_message(node: node, preferred_expression: preferred_expression)
          ) do |corrector|
            if derived_from_braceless_interpolation?(node)
              preferred_expression = "{#{preferred_expression}}"
            end

            corrector.replace(node, preferred_expression)
          end
        end
      end
    end
  end
end
