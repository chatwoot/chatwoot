# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of output calls like puts and print
      #
      # @safety
      #   This cop's autocorrection is unsafe because depending on the Rails log level configuration,
      #   changing from `puts` to `Rails.logger.debug` could result in no output being shown.
      #
      # @example
      #   # bad
      #   puts 'A debug message'
      #   pp 'A debug message'
      #   print 'A debug message'
      #
      #   # good
      #   Rails.logger.debug 'A debug message'
      class Output < Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Do not write to stdout. Use Rails's logger if you want to log."
        RESTRICT_ON_SEND = %i[ap p pp pretty_print print puts binwrite syswrite write write_nonblock].freeze

        def_node_matcher :output?, <<~PATTERN
          (send nil? {:ap :p :pp :pretty_print :print :puts} ...)
        PATTERN

        def_node_matcher :io_output?, <<~PATTERN
          (send
            {
              (gvar #match_gvar?)
              (const {nil? cbase} {:STDOUT :STDERR})
            }
            {:binwrite :syswrite :write :write_nonblock}
            ...)
        PATTERN

        def on_send(node)
          return if node.parent&.call_type? || node.block_node
          return if !output?(node) && !io_output?(node)

          range = offense_range(node)

          add_offense(range) do |corrector|
            corrector.replace(range, 'Rails.logger.debug')
          end
        end

        private

        def match_gvar?(sym)
          %i[$stdout $stderr].include?(sym)
        end

        def offense_range(node)
          if node.receiver
            range_between(node.source_range.begin_pos, node.loc.selector.end_pos)
          else
            node.loc.selector
          end
        end
      end
    end
  end
end
