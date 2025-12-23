# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for expanded date range. It only compatible `..` range is targeted.
      # Incompatible `...` range is ignored.
      #
      # @example
      #   # bad
      #   date.beginning_of_day..date.end_of_day
      #   date.beginning_of_week..date.end_of_week
      #   date.beginning_of_month..date.end_of_month
      #   date.beginning_of_quarter..date.end_of_quarter
      #   date.beginning_of_year..date.end_of_year
      #
      #   # good
      #   date.all_day
      #   date.all_week
      #   date.all_month
      #   date.all_quarter
      #   date.all_year
      #
      class ExpandedDateRange < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use `%<preferred_method>s` instead.'

        minimum_target_rails_version 5.1

        PREFERRED_METHODS = {
          beginning_of_day: 'all_day',
          beginning_of_week: 'all_week',
          beginning_of_month: 'all_month',
          beginning_of_quarter: 'all_quarter',
          beginning_of_year: 'all_year'
        }.freeze

        MAPPED_DATE_RANGE_METHODS = {
          beginning_of_day: :end_of_day,
          beginning_of_week: :end_of_week,
          beginning_of_month: :end_of_month,
          beginning_of_quarter: :end_of_quarter,
          beginning_of_year: :end_of_year
        }.freeze

        def on_irange(node)
          begin_node = node.begin
          end_node = node.end
          return if allow?(begin_node, end_node)

          preferred_method = preferred_method(begin_node)
          if begin_node.method?(:beginning_of_week) && begin_node.arguments.one? && end_node.arguments.one?
            return unless same_argument?(begin_node, end_node)

            preferred_method << "(#{begin_node.first_argument.source})"
          elsif any_arguments?(begin_node, end_node)
            return
          end

          register_offense(node, preferred_method)
        end

        private

        def allow?(begin_node, end_node)
          return true unless (begin_source = receiver_source(begin_node))
          return true unless (end_source = receiver_source(end_node))

          begin_source != end_source || MAPPED_DATE_RANGE_METHODS[begin_node.method_name] != end_node.method_name
        end

        def receiver_source(node)
          return if !node&.send_type? || node.receiver.nil?

          node.receiver.source
        end

        def same_argument?(begin_node, end_node)
          begin_node.first_argument.source == end_node.first_argument.source
        end

        def preferred_method(begin_node)
          +"#{begin_node.receiver.source}.#{PREFERRED_METHODS[begin_node.method_name]}"
        end

        def any_arguments?(begin_node, end_node)
          begin_node.arguments.any? || end_node.arguments.any?
        end

        def register_offense(node, preferred_method)
          message = format(MSG, preferred_method: preferred_method)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, preferred_method)
          end
        end
      end
    end
  end
end
