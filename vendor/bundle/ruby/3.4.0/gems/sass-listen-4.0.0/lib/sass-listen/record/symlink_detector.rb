require 'set'

module SassListen
  # @private api
  class Record
    class SymlinkDetector
      WIKI = 'https://github.com/guard/listen/wiki/Duplicate-directory-errors'

      SYMLINK_LOOP_ERROR = <<-EOS
        ** ERROR: directory is already being watched! **

        Directory: %s

        is already being watched through: %s

        MORE INFO: #{WIKI}
      EOS

      class Error < RuntimeError
      end

      def initialize
        @real_dirs = Set.new
      end

      def verify_unwatched!(entry)
        real_path = entry.real_path
        @real_dirs.add?(real_path) || _fail(entry.sys_path, real_path)
      end

      private

      def _fail(symlinked, real_path)
        STDERR.puts format(SYMLINK_LOOP_ERROR, symlinked, real_path)
        fail Error, 'Failed due to looped symlinks'
      end
    end
  end
end
