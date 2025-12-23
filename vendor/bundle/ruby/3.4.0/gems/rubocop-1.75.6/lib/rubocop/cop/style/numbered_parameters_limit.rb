# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Detects use of an excessive amount of numbered parameters in a
      # single block. Having too many numbered parameters can make code too
      # cryptic and hard to read.
      #
      # The cop defaults to registering an offense if there is more than 1 numbered
      # parameter but this maximum can be configured by setting `Max`.
      #
      # @example Max: 1 (default)
      #   # bad
      #   use_multiple_numbered_parameters { _1.call(_2, _3, _4) }
      #
      #   # good
      #   array.each { use_array_element_as_numbered_parameter(_1) }
      #   hash.each { use_only_hash_value_as_numbered_parameter(_2) }
      class NumberedParametersLimit < Base
        extend TargetRubyVersion
        extend ExcludeLimit

        DEFAULT_MAX_VALUE = 1

        minimum_target_ruby_version 2.7
        exclude_limit 'Max'

        MSG = 'Avoid using more than %<max>i numbered %<parameter>s; %<count>i detected.'
        NUMBERED_PARAMETER_PATTERN = /\A_[1-9]\z/.freeze

        def on_numblock(node)
          param_count = numbered_parameter_nodes(node).uniq.count
          return if param_count <= max_count

          parameter = max_count > 1 ? 'parameters' : 'parameter'
          message = format(MSG, max: max_count, parameter: parameter, count: param_count)
          add_offense(node, message: message) { self.max = param_count }
        end

        private

        def numbered_parameter_nodes(node)
          node.each_descendant(:lvar).select do |lvar_node|
            lvar_node.source.match?(NUMBERED_PARAMETER_PATTERN)
          end
        end

        def max_count
          max = cop_config.fetch('Max', DEFAULT_MAX_VALUE)

          # Ruby does not allow more than 9 numbered parameters
          [max, 9].min
        end
      end
    end
  end
end
