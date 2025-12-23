# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that blocks are used for interpolated strings passed to
      # `Rails.logger.debug`.
      #
      # By default, Rails production environments use the `:info` log level.
      # At the `:info` log level, `Rails.logger.debug` statements do not result
      # in log output. However, Ruby must eagerly evaluate interpolated string
      # arguments passed as method arguments. Passing a block to
      # `Rails.logger.debug` prevents costly evaluation of interpolated strings
      # when no output would be produced anyway.
      #
      # @example
      #   # bad
      #   Rails.logger.debug "The time is #{Time.zone.now}."
      #
      #   # good
      #   Rails.logger.debug { "The time is #{Time.zone.now}." }
      #
      class EagerEvaluationLogMessage < Base
        extend AutoCorrector

        MSG = 'Pass a block to `Rails.logger.debug`.'
        RESTRICT_ON_SEND = %i[debug].freeze

        def_node_matcher :interpolated_string_passed_to_debug, <<~PATTERN
          (send
            (send
              (const {cbase nil?} :Rails)
              :logger
            )
            :debug
            $(dstr ...)
          )
        PATTERN

        def self.autocorrect_incompatible_with
          [Style::MethodCallWithArgsParentheses]
        end

        def on_send(node)
          return if node.parent&.block_type?

          interpolated_string_passed_to_debug(node) do |arguments|
            range = replacement_range(node)
            replacement = replacement_source(node, arguments)

            add_offense(range) do |corrector|
              corrector.replace(range, replacement)
            end
          end
        end

        private

        def replacement_range(node)
          stop = node.source_range.end
          start = node.loc.selector.end

          if node.parenthesized_call?
            stop.with(begin_pos: start.begin_pos)
          else
            stop.with(begin_pos: start.begin_pos + 1)
          end
        end

        def replacement_source(node, arguments)
          if node.parenthesized_call?
            " { #{arguments.source} }"
          else
            "{ #{arguments.source} }"
          end
        end
      end
    end
  end
end
