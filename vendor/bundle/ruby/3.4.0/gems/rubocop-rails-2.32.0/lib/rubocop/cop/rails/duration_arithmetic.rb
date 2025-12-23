# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks if a duration is added to or subtracted from `Time.current`.
      #
      # @example
      #   # bad
      #   Time.current - 1.minute
      #   Time.current + 2.days
      #
      #   # good - using relative would make it harder to express and read
      #   Date.yesterday + 3.days
      #   created_at - 1.minute
      #   3.days - 1.hour
      #
      #   # good
      #   1.minute.ago
      #   2.days.from_now
      class DurationArithmetic < Base
        extend AutoCorrector

        MSG = 'Do not add or subtract duration.'

        RESTRICT_ON_SEND = %i[+ -].freeze

        DURATIONS = Set[:second, :seconds, :minute, :minutes, :hour, :hours,
                        :day, :days, :week, :weeks, :fortnight, :fortnights,
                        :month, :months, :year, :years]

        # @!method duration_arithmetic_argument?(node)
        #   Match duration subtraction or addition with current time.
        #
        #   @example source that matches
        #     Time.current - 1.hour
        #
        #   @example source that matches
        #     ::Time.zone.now + 1.hour
        #
        #   @param node [RuboCop::AST::Node]
        #   @yield operator and duration
        def_node_matcher :duration_arithmetic_argument?, <<~PATTERN
          (send #time_current? ${ :+ :- } $#duration?)
        PATTERN

        # @!method duration?(node)
        #   Match a literal Duration
        #
        #   @example source that matches
        #     1.hour
        #
        #   @example source that matches
        #     9.5.weeks
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Boolean] true if matches
        def_node_matcher :duration?, '(send { int float (send nil _) } DURATIONS)'

        # @!method time_current?(node)
        #   Match Time.current
        #
        #   @example source that matches
        #     Time.current
        #
        #   @example source that matches
        #     ::Time.zone.now
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Boolean] true if matches
        def_node_matcher :time_current?, <<~PATTERN
          {
            (send (const {nil? cbase} :Time) :current)
            (send (send (const {nil? cbase} :Time) :zone) :now)
          }
        PATTERN

        def on_send(node)
          duration_arithmetic_argument?(node) do |*operation|
            add_offense(node) do |corrector|
              corrector.replace(node, corrected_source(*operation))
            end
          end
        end

        private

        def corrected_source(operator, duration)
          if operator == :-
            "#{duration.source}.ago"
          else
            "#{duration.source}.from_now"
          end
        end
      end
    end
  end
end
