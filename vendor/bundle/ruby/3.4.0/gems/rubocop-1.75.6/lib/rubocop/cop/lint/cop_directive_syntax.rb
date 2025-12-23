# frozen_string_literal: true

# rubocop:disable Lint/RedundantCopDisableDirective
# rubocop:disable Style/DoubleCopDisableDirective
module RuboCop
  module Cop
    module Lint
      # Checks that `# rubocop:enable ...` and `# rubocop:disable ...` statements
      # are strictly formatted.
      #
      # A comment can be added to the directive by prefixing it with `--`.
      #
      # @example
      #   # bad
      #   # rubocop:disable Layout/LineLength Style/Encoding
      #   #                                  ^ missing comma
      #
      #   # bad
      #   # rubocop:disable
      #
      #   # bad
      #   # rubocop:disable Layout/LineLength # rubocop:disable Style/Encoding
      #
      #   # bad
      #   # rubocop:wrongmode Layout/LineLength
      #
      #   # good
      #   # rubocop:disable Layout/LineLength
      #
      #   # good
      #   # rubocop:disable Layout/LineLength, Style/Encoding
      #
      #   # good
      #   # rubocop:disable all
      #
      #   # good
      #   # rubocop:disable Layout/LineLength -- This is a good comment.
      #
      class CopDirectiveSyntax < Base
        COMMON_MSG = 'Malformed directive comment detected.'

        MISSING_MODE_NAME_MSG = 'The mode name is missing.'
        INVALID_MODE_NAME_MSG = 'The mode name must be one of `enable`, `disable`, or `todo`.'
        MISSING_COP_NAME_MSG = 'The cop name is missing.'
        MALFORMED_COP_NAMES_MSG = 'Cop names must be separated by commas. ' \
                                  'Comment in the directive must start with `--`.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            directive_comment = DirectiveComment.new(comment)
            next unless directive_comment.start_with_marker?
            next unless directive_comment.malformed?

            message = offense_message(directive_comment)
            add_offense(comment, message: message)
          end
        end

        private

        # rubocop:disable Metrics/MethodLength
        def offense_message(directive_comment)
          comment = directive_comment.comment
          after_marker = comment.text.sub(DirectiveComment::DIRECTIVE_MARKER_REGEXP, '')
          mode = after_marker.split(' ', 2).first
          additional_msg = if mode.nil?
                             MISSING_MODE_NAME_MSG
                           elsif !DirectiveComment::AVAILABLE_MODES.include?(mode)
                             INVALID_MODE_NAME_MSG
                           elsif directive_comment.missing_cop_name?
                             MISSING_COP_NAME_MSG
                           else
                             MALFORMED_COP_NAMES_MSG
                           end

          "#{COMMON_MSG} #{additional_msg}"
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
# rubocop:enable Lint/RedundantCopDisableDirective
# rubocop:enable Style/DoubleCopDisableDirective
