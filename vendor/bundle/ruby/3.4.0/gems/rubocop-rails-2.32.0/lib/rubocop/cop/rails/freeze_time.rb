# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies usages of `travel_to` with an argument of the current time and
      # change them to use `freeze_time` instead.
      #
      # @safety
      #   This cop’s autocorrection is unsafe because `freeze_time` just delegates to
      #   `travel_to` with a default `Time.now`, it is not strictly equivalent to `Time.now`
      #   if the argument of `travel_to` is the current time considering time zone.
      #
      # @example
      #   # bad
      #   travel_to(Time.now)
      #   travel_to(Time.new)
      #   travel_to(DateTime.now)
      #   travel_to(Time.current)
      #   travel_to(Time.zone.now)
      #   travel_to(Time.now.in_time_zone)
      #   travel_to(Time.current.to_time)
      #
      #   # good
      #   freeze_time
      #
      class FreezeTime < Base
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 5.2

        MSG = 'Use `freeze_time` instead of `travel_to`.'
        NOW_METHODS = %i[now new current].freeze
        CONVERT_METHODS = %i[to_time in_time_zone].freeze
        RESTRICT_ON_SEND = %i[travel_to].freeze

        # @!method time_now?(node)
        def_node_matcher :time_now?, <<~PATTERN
          (const {nil? cbase} {:Time :DateTime})
        PATTERN

        # @!method zoned_time_now?(node)
        def_node_matcher :zoned_time_now?, <<~PATTERN
          (send (const {nil? cbase} :Time) :zone)
        PATTERN

        def on_send(node)
          child_node, method_name, time_argument = *node.first_argument&.children
          return if time_argument || !child_node
          return unless current_time?(child_node, method_name) || current_time_with_convert?(child_node, method_name)

          add_offense(node) do |corrector|
            last_argument = node.last_argument
            freeze_time_method = last_argument.block_pass_type? ? "freeze_time(#{last_argument.source})" : 'freeze_time'
            corrector.replace(node, freeze_time_method)
          end
        end

        private

        def current_time?(node, method_name)
          return false unless NOW_METHODS.include?(method_name)

          node.send_type? ? zoned_time_now?(node) : time_now?(node)
        end

        def current_time_with_convert?(node, method_name)
          return false unless CONVERT_METHODS.include?(method_name)

          child_node, child_method_name, time_argument = *node.children
          return false if time_argument

          current_time?(child_node, child_method_name)
        end
      end
    end
  end
end
