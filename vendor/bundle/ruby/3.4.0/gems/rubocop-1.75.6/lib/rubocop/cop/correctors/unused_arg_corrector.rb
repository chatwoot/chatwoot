# frozen_string_literal: true

module RuboCop
  module Cop
    # This autocorrects unused arguments.
    class UnusedArgCorrector
      extend RangeHelp

      class << self
        attr_reader :processed_source

        def correct(corrector, processed_source, node)
          return if %i[kwarg kwoptarg].include?(node.type)

          @processed_source = processed_source

          if node.blockarg_type?
            correct_for_blockarg_type(corrector, node)
          else
            variable_name = if node.optarg_type?
                              node.node_parts[0]
                            else
                              # Extract only a var name without splat (`*`)
                              node.source.gsub(/\A\*+/, '')
                            end

            corrector.replace(node.loc.name, "_#{variable_name}")
          end
        end

        def correct_for_blockarg_type(corrector, node)
          range = range_with_surrounding_space(node.source_range, side: :left)
          range = range_with_surrounding_comma(range, :left)

          corrector.remove(range)
        end
      end
    end
  end
end
