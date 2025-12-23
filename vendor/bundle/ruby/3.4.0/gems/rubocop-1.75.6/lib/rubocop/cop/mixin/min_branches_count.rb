# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking minimum branches count.
    module MinBranchesCount
      private

      def min_branches_count?(node)
        branches =
          if node.case_type?
            node.when_branches
          elsif node.if_type?
            if_conditional_branches(node)
          else
            raise ArgumentError, "Unsupported #{node.type.inspect} node type"
          end

        branches.size >= min_branches_count
      end

      def min_branches_count
        length = cop_config['MinBranchesCount'] || 3
        return length if length.is_a?(Integer) && length.positive?

        raise 'MinBranchesCount needs to be a positive integer!'
      end

      def if_conditional_branches(node, branches = [])
        return [] if node.nil? || !node.if_type?

        branches << node.if_branch

        else_branch = node.else_branch
        if_conditional_branches(else_branch, branches) if else_branch&.if_type?
        branches
      end
    end
  end
end
