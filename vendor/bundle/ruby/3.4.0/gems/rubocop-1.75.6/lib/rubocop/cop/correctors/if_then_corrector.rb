# frozen_string_literal: true

module RuboCop
  module Cop
    # This class autocorrects `if...then` structures to a multiline `if` statement
    class IfThenCorrector
      DEFAULT_INDENTATION_WIDTH = 2

      def initialize(if_node, indentation: nil)
        @if_node = if_node
        @indentation = indentation || DEFAULT_INDENTATION_WIDTH
      end

      def call(corrector)
        corrector.replace(if_node, replacement)
      end

      private

      attr_reader :if_node, :indentation

      def replacement(node = if_node, indentation = nil)
        indentation = ' ' * node.source_range.column if indentation.nil?
        if_branch_source = node.if_branch&.source || 'nil'
        elsif_indentation = indentation if node.respond_to?(:elsif?) && node.elsif?

        if_branch = <<~RUBY
          #{elsif_indentation}#{node.keyword} #{node.condition.source}
          #{indentation}#{branch_body_indentation}#{if_branch_source}
        RUBY

        else_branch = rewrite_else_branch(node.else_branch, indentation)
        if_branch + else_branch
      end

      def rewrite_else_branch(else_branch, indentation)
        if else_branch.nil?
          'end'
        elsif else_branch.if_type? && else_branch.elsif?
          replacement(else_branch, indentation)
        else
          <<~RUBY.chomp
            #{indentation}else
            #{indentation}#{branch_body_indentation}#{else_branch.source}
            #{indentation}end
          RUBY
        end
      end

      def branch_body_indentation
        @branch_body_indentation ||= (' ' * indentation).freeze
      end
    end
  end
end
