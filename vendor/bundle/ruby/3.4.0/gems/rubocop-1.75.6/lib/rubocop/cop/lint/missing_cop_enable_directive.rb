# frozen_string_literal: true

# rubocop:disable Lint/RedundantCopDisableDirective
module RuboCop
  module Cop
    module Lint
      # Checks that there is an `# rubocop:enable ...` statement
      # after a `# rubocop:disable ...` statement. This will prevent leaving
      # cop disables on wide ranges of code, that latter contributors to
      # a file wouldn't be aware of.
      #
      # @example
      #   # Lint/MissingCopEnableDirective:
      #   #   MaximumRangeSize: .inf
      #
      #   # good
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   # rubocop:enable Layout/SpaceAroundOperators
      #   # y = 1
      #   # EOF
      #
      #   # bad
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   # EOF
      #
      # @example
      #   # Lint/MissingCopEnableDirective:
      #   #   MaximumRangeSize: 2
      #
      #   # good
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   # With the previous, there are 2 lines on which cop is disabled.
      #   # rubocop:enable Layout/SpaceAroundOperators
      #
      #   # bad
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   x += 1
      #   # Including this, that's 3 lines on which the cop is disabled.
      #   # rubocop:enable Layout/SpaceAroundOperators
      #
      class MissingCopEnableDirective < Base
        include RangeHelp

        MSG = 'Re-enable %<cop>s %<type>s with `# rubocop:enable` after disabling it.'
        MSG_BOUND = 'Re-enable %<cop>s %<type>s within %<max_range>s lines after disabling it.'

        def on_new_investigation
          each_missing_enable do |cop, line_range|
            next if acceptable_range?(cop, line_range)

            range = source_range(processed_source.buffer, line_range.min, 0..0)
            comment = processed_source.comment_at_line(line_range.begin)

            add_offense(range, message: message(cop, comment))
          end
        end

        private

        def each_missing_enable
          processed_source.disabled_line_ranges.each do |cop, line_ranges|
            line_ranges.each { |line_range| yield cop, line_range }
          end
        end

        def acceptable_range?(cop, line_range)
          # This has to remain a strict inequality to handle
          # the case when max_range is Float::INFINITY
          return true if line_range.max - line_range.min < max_range + 2
          # This cop is disabled in the config, it is not expected to be re-enabled
          return true if line_range.min == CommentConfig::CONFIG_DISABLED_LINE_RANGE_MIN

          cop_class = RuboCop::Cop::Registry.global.find_by_cop_name cop
          if cop_class &&
             !processed_source.registry.enabled?(cop_class, config) &&
             line_range.max == Float::INFINITY
            return true
          end

          false
        end

        def max_range
          @max_range ||= cop_config['MaximumRangeSize']
        end

        def message(cop, comment, type = 'cop')
          if department_enabled?(cop, comment)
            type = 'department'
            cop = cop.split('/').first
          end

          if max_range == Float::INFINITY
            format(MSG, cop: cop, type: type)
          else
            format(MSG_BOUND, cop: cop, type: type, max_range: max_range)
          end
        end

        def department_enabled?(cop, comment)
          DirectiveComment.new(comment).in_directive_department?(cop)
        end
      end
    end
  end
end
# rubocop:enable Lint/RedundantCopDisableDirective
