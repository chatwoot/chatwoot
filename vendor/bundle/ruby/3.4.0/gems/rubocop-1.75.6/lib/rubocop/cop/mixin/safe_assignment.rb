# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for safe assignment. By safe assignment we mean
    # putting parentheses around an assignment to indicate "I know I'm using an
    # assignment as a condition. It's not a mistake."
    module SafeAssignment
      extend NodePattern::Macros

      private

      # @!method empty_condition?(node)
      def_node_matcher :empty_condition?, '(begin)'

      # @!method setter_method?(node)
      def_node_matcher :setter_method?, '[(call ...) setter_method?]'

      # @!method safe_assignment?(node)
      def_node_matcher :safe_assignment?, '(begin {equals_asgn? #setter_method?})'

      def safe_assignment_allowed?
        cop_config['AllowSafeAssignment']
      end
    end
  end
end
