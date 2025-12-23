# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for trailing inline comments.
      #
      # @example
      #
      #   # good
      #   foo.each do |f|
      #     # Standalone comment
      #     f.bar
      #   end
      #
      #   # bad
      #   foo.each do |f|
      #     f.bar # Trailing inline comment
      #   end
      class InlineComment < Base
        MSG = 'Avoid trailing inline comments.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            next if comment_line?(processed_source[comment.loc.line - 1]) ||
                    comment.text.match?(/\A# rubocop:(enable|disable)/)

            add_offense(comment)
          end
        end
      end
    end
  end
end
