# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Enforces that Ruby source files are not empty.
      #
      # @example
      #   # bad
      #   # Empty file
      #
      #   # good
      #   # File containing non commented source lines
      #
      # @example AllowComments: true (default)
      #   # good
      #   # File consisting only of comments
      #
      # @example AllowComments: false
      #   # bad
      #   # File consisting only of comments
      #
      class EmptyFile < Base
        MSG = 'Empty file detected.'

        def on_new_investigation
          add_global_offense(MSG) if offending?
        end

        private

        def offending?
          empty_file? || (!cop_config['AllowComments'] && contains_only_comments?)
        end

        def empty_file?
          processed_source.buffer.source.empty?
        end

        def contains_only_comments?
          processed_source.lines.all? { |line| line.blank? || comment_line?(line) }
        end
      end
    end
  end
end
