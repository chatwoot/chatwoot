# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `map { ... }.flatten` and
      # change them to use `flat_map { ... }` instead.
      #
      # @example
      #   # bad
      #   [1, 2, 3, 4].map { |e| [e, e] }.flatten(1)
      #   [1, 2, 3, 4].collect { |e| [e, e] }.flatten(1)
      #
      #   # good
      #   [1, 2, 3, 4].flat_map { |e| [e, e] }
      #   [1, 2, 3, 4].map { |e| [e, e] }.flatten
      #   [1, 2, 3, 4].collect { |e| [e, e] }.flatten
      class FlatMap < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `flat_map` instead of `%<method>s...%<flatten>s`.'
        RESTRICT_ON_SEND = %i[flatten flatten!].freeze
        FLATTEN_MULTIPLE_LEVELS = ' Beware, `flat_map` only flattens 1 level ' \
                                  'and `flatten` can be used to flatten ' \
                                  'multiple levels.'

        def_node_matcher :flat_map_candidate?, <<~PATTERN
          (call
            {
              $(block (call _ ${:collect :map}) ...)
              $(call _ ${:collect :map} (block_pass _))
            }
            ${:flatten :flatten!}
            $...
          )
        PATTERN

        def on_send(node)
          flat_map_candidate?(node) do |map_node, first_method, flatten, params|
            flatten_level, = *params.first
            if cop_config['EnabledForFlattenWithoutParams'] && !flatten_level
              offense_for_levels(node, map_node, first_method, flatten)
            elsif flatten_level == 1
              offense_for_method(node, map_node, first_method, flatten)
            end
          end
        end
        alias on_csend on_send

        private

        def offense_for_levels(node, map_node, first_method, flatten)
          message = MSG + FLATTEN_MULTIPLE_LEVELS

          register_offense(node, map_node, first_method, flatten, message)
        end

        def offense_for_method(node, map_node, first_method, flatten)
          register_offense(node, map_node, first_method, flatten, MSG)
        end

        def register_offense(node, map_node, first_method, flatten, message)
          map_send_node = map_node.block_type? ? map_node.send_node : map_node
          range = range_between(map_send_node.loc.selector.begin_pos, node.source_range.end_pos)
          message = format(message, method: first_method, flatten: flatten)

          add_offense(range, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def autocorrect(corrector, node)
          map_node, _first_method, _flatten, params = flat_map_candidate?(node)
          flatten_level, = *params.first

          return unless flatten_level

          map_send_node = map_node.block_type? ? map_node.send_node : map_node
          range = range_between(map_node.source_range.end_pos, node.source_range.end_pos)

          corrector.remove(range)
          corrector.replace(map_send_node.loc.selector, 'flat_map')
        end
      end
    end
  end
end
