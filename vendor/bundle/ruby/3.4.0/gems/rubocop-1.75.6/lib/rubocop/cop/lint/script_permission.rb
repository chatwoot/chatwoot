# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks if a file which has a shebang line as
      # its first line is granted execute permission.
      #
      # @example
      #   # bad
      #
      #   # A file which has a shebang line as its first line is not
      #   # granted execute permission.
      #
      #   #!/usr/bin/env ruby
      #   puts 'hello, world'
      #
      #   # good
      #
      #   # A file which has a shebang line as its first line is
      #   # granted execute permission.
      #
      #   #!/usr/bin/env ruby
      #   puts 'hello, world'
      #
      #   # good
      #
      #   # A file which has not a shebang line as its first line is not
      #   # granted execute permission.
      #
      #   puts 'hello, world'
      #
      class ScriptPermission < Base
        extend AutoCorrector

        MSG = "Script file %<file>s doesn't have execute permission."
        SHEBANG = '#!'

        def on_new_investigation
          return if @options.key?(:stdin)
          return if Platform.windows?
          return unless processed_source.start_with?(SHEBANG)
          return if executable?(processed_source)

          comment = processed_source.comments[0]
          message = format_message_from(processed_source)

          add_offense(comment, message: message) do
            autocorrect if autocorrect_requested?
          end
        end

        private

        def autocorrect
          FileUtils.chmod('+x', processed_source.file_path)
        end

        def executable?(processed_source)
          # Returns true if stat is executable or if the operating system
          # doesn't distinguish executable files from nonexecutable files.
          # See at: https://github.com/ruby/ruby/blob/ruby_2_4/file.c#L5362
          File.stat(processed_source.file_path).executable?
        end

        def format_message_from(processed_source)
          basename = File.basename(processed_source.file_path)
          format(MSG, file: basename)
        end
      end
    end
  end
end
