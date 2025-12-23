# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.7, `Enumerable#filter_map` has been added.
      #
      # This cop identifies places where `select.map` can be replaced by `filter_map`.
      #
      # @example
      #   # bad
      #   ary.select(&:foo).map(&:bar)
      #   ary.filter(&:foo).map(&:bar)
      #
      #   # good
      #   ary.filter_map { |o| o.bar if o.foo }
      #
      class SelectMap < Base
        include RangeHelp
        extend TargetRubyVersion

        minimum_target_ruby_version 2.7

        MSG = 'Use `filter_map` instead of `%<method_name>s.map`.'
        RESTRICT_ON_SEND = %i[select filter].freeze

        def on_send(node)
          return if (first_argument = node.first_argument) && !first_argument.block_pass_type?
          return unless (send_node = map_method_candidate(node))
          return unless send_node.method?(:map)

          map_method = send_node.parent&.block_type? ? send_node.parent : send_node

          range = offense_range(node, map_method)
          add_offense(range, message: format(MSG, method_name: node.method_name))
        end
        alias on_csend on_send

        private

        def map_method_candidate(node)
          return unless (parent = node.parent)

          if parent.block_type? && parent.parent&.call_type?
            parent.parent
          elsif parent.call_type?
            parent
          end
        end

        def offense_range(node, map_method)
          range_between(node.loc.selector.begin_pos, map_method.source_range.end_pos)
        end
      end
    end
  end
end
