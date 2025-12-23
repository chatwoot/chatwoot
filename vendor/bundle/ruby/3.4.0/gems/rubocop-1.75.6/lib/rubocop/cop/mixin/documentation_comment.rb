# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking documentation.
    module DocumentationComment
      extend NodePattern::Macros

      private

      def documentation_comment?(node)
        preceding_lines = preceding_lines(node)

        return false unless preceding_comment?(node, preceding_lines.last)

        preceding_lines.any? do |comment|
          !AnnotationComment.new(comment, annotation_keywords).annotation? &&
            !interpreter_directive_comment?(comment) &&
            !rubocop_directive_comment?(comment)
        end
      end

      # The args node1 & node2 may represent a RuboCop::AST::Node
      # or a Parser::Source::Comment. Both respond to #loc.
      def preceding_comment?(node1, node2)
        node1 && node2 && precede?(node2, node1) && comment_line?(node2.source)
      end

      # The args node1 & node2 may represent a RuboCop::AST::Node
      # or a Parser::Source::Comment. Both respond to #loc.
      def precede?(node1, node2)
        node2.loc.line - node1.loc.line == 1
      end

      def preceding_lines(node)
        processed_source.ast_with_comments[node].select { |line| line.loc.line < node.loc.line }
      end

      def interpreter_directive_comment?(comment)
        /^#\s*(frozen_string_literal|encoding):/.match?(comment.text)
      end

      def rubocop_directive_comment?(comment)
        !!DirectiveComment.new(comment).match_captures
      end

      def annotation_keywords
        config.for_cop('Style/CommentAnnotation')['Keywords']
      end
    end
  end
end
