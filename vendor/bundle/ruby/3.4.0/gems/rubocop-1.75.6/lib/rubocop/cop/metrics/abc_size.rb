# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks that the ABC size of methods is not higher than the
      # configured maximum. The ABC size is based on assignments, branches
      # (method calls), and conditions. See http://c2.com/cgi/wiki?AbcMetric
      # and https://en.wikipedia.org/wiki/ABC_Software_Metric.
      #
      # Interpreting ABC size:
      #
      # * ``<= 17`` satisfactory
      # * `18..30` unsatisfactory
      # * `>` 30 dangerous
      #
      # You can have repeated "attributes" calls count as a single "branch".
      # For this purpose, attributes are any method with no argument; no attempt
      # is meant to distinguish actual `attr_reader` from other methods.
      #
      # @example CountRepeatedAttributes: false (default is true)
      #
      #    # `model` and `current_user`, referenced 3 times each,
      #    # are each counted as only 1 branch each if
      #    # `CountRepeatedAttributes` is set to 'false'
      #
      #    def search
      #      @posts = model.active.visible_by(current_user)
      #                .search(params[:q])
      #      @posts = model.some_process(@posts, current_user)
      #      @posts = model.another_process(@posts, current_user)
      #
      #      render 'pages/search/page'
      #    end
      #
      # This cop also takes into account `AllowedMethods` (defaults to `[]`)
      # And `AllowedPatterns` (defaults to `[]`)
      #
      class AbcSize < Base
        include MethodComplexity

        MSG = 'Assignment Branch Condition size for %<method>s is too high. ' \
              '[%<abc_vector>s %<complexity>.4g/%<max>.4g]'

        private

        def complexity(node)
          Utils::AbcSizeCalculator.calculate(
            node,
            discount_repeated_attributes: !cop_config['CountRepeatedAttributes']
          )
        end
      end
    end
  end
end
