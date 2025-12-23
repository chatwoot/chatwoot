# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for usage of `File.open` in append mode with empty block.
      #
      # Such a usage only creates a new file, but it doesn't update
      # timestamps for an existing file, which might have been the intention.
      #
      # For example, for an existing file `foo.txt`:
      #
      #   ruby -e "puts File.mtime('foo.txt')"
      #   # 2024-11-26 12:17:23 +0100
      #
      #   ruby -e "File.open('foo.txt', 'a') {}"
      #
      #   ruby -e "puts File.mtime('foo.txt')"
      #   # 2024-11-26 12:17:23 +0100 -> unchanged
      #
      # If the intention was to update timestamps, `FileUtils.touch('foo.txt')`
      # should be used instead.
      #
      # @safety
      #   Autocorrection is unsafe for this cop because unlike `File.open`,
      #   `FileUtils.touch` updates an existing file's timestamps.
      #
      # @example
      #   # bad
      #   File.open(filename, 'a') {}
      #   File.open(filename, 'a+') {}
      #
      #   # good
      #   FileUtils.touch(filename)
      #
      class FileTouch < Base
        extend AutoCorrector

        MSG = 'Use `FileUtils.touch(%<argument>s)` instead of `File.open` in ' \
              'append mode with empty block.'

        RESTRICT_ON_SEND = %i[open].freeze

        APPEND_FILE_MODES = %w[a a+ ab a+b at a+t].to_set.freeze

        # @!method file_open?(node)
        def_node_matcher :file_open?, <<~PATTERN
          (send
            (const {nil? cbase} :File) :open
            $(...)
            (str %APPEND_FILE_MODES))
        PATTERN

        def on_send(node)
          filename = file_open?(node)
          parent = node.parent

          return unless filename
          return unless parent && empty_block?(parent)

          message = format(MSG, argument: filename.source)
          add_offense(parent, message: message) do |corrector|
            corrector.replace(parent, "FileUtils.touch(#{filename.source})")
          end
        end

        private

        def empty_block?(node)
          node.block_type? && !node.body
        end
      end
    end
  end
end
