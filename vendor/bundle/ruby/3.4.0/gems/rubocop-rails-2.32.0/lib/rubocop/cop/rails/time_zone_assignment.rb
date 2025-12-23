# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of `Time.zone=` method.
      #
      # The `zone` attribute persists for the rest of the Ruby runtime, potentially causing
      # unexpected behavior at a later time.
      # Using `Time.use_zone` ensures the code passed in the block is the only place Time.zone is affected.
      # It eliminates the possibility of a `zone` sticking around longer than intended.
      #
      # @example
      #   # bad
      #   Time.zone = 'EST'
      #
      #   # good
      #   Time.use_zone('EST') do
      #   end
      #
      class TimeZoneAssignment < Base
        MSG = 'Use `Time.use_zone` with block instead of `Time.zone=`.'
        RESTRICT_ON_SEND = %i[zone=].freeze

        def_node_matcher :time_zone_assignment?, <<~PATTERN
          (send (const {nil? cbase} :Time) :zone= ...)
        PATTERN

        def on_send(node)
          return unless time_zone_assignment?(node)

          add_offense(node)
        end
      end
    end
  end
end
