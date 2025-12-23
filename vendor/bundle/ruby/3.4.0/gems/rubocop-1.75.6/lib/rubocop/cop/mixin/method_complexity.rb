# frozen_string_literal: true

module RuboCop
  module Cop
    # @api private
    #
    # This module handles measurement and reporting of complexity in methods.
    module MethodComplexity
      include AllowedMethods
      include AllowedPattern
      include Metrics::Utils::RepeatedCsendDiscount
      extend NodePattern::Macros
      extend ExcludeLimit

      exclude_limit 'Max'

      def on_def(node)
        return if allowed_method?(node.method_name) || matches_allowed_pattern?(node.method_name)

        check_complexity(node, node.method_name)
      end
      alias on_defs on_def

      def on_block(node)
        define_method?(node) do |name|
          return if allowed_method?(name) || matches_allowed_pattern?(name)

          check_complexity(node, name)
        end
      end

      alias on_numblock on_block
      alias on_itblock on_block

      private

      # @!method define_method?(node)
      def_node_matcher :define_method?, <<~PATTERN
        (any_block
         (send nil? :define_method ({sym str} $_)) _ _)
      PATTERN

      def check_complexity(node, method_name)
        # Accepts empty methods always.
        return unless node.body

        max = cop_config['Max']
        reset_repeated_csend
        complexity, abc_vector = complexity(node.body)

        return unless complexity > max

        msg = format(
          self.class::MSG,
          method: method_name, complexity: complexity, abc_vector: abc_vector, max: max
        )
        location = location(node)

        add_offense(location, message: msg) { self.max = complexity.ceil }
      end

      def complexity(body)
        score = 1
        body.each_node(:lvasgn, *self.class::COUNTED_NODES) do |node|
          if node.lvasgn_type?
            reset_on_lvasgn(node)
          else
            score += complexity_score_for(node)
          end
        end
        score
      end

      def location(node)
        if LSP.enabled?
          end_range = node.loc.respond_to?(:name) ? node.loc.name : node.loc.begin
          node.source_range.begin.join(end_range)
        else
          node.source_range
        end
      end
    end
  end
end
