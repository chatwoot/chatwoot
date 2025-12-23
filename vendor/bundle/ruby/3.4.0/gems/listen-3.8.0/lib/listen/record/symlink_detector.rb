# frozen_string_literal: true

require 'set'
require 'listen/error'

module Listen
  # @private api
  class Record
    class SymlinkDetector
      README_URL = 'https://github.com/guard/listen/blob/master/README.md'

      SYMLINK_LOOP_ERROR = <<-EOS
        ** ERROR: directory is already being watched! **

        Directory: %s

        is already being watched through: %s

        MORE INFO: #{README_URL}
      EOS

      Error = ::Listen::Error # for backward compatibility

      def initialize
        @real_dirs = Set.new
      end

      def verify_unwatched!(entry)
        real_path = entry.real_path
        @real_dirs.add?(real_path) or _fail(entry.sys_path, real_path)
      end

      private

      def _fail(symlinked, real_path)
        warn(format(SYMLINK_LOOP_ERROR, symlinked, real_path))
        raise ::Listen::Error::SymlinkLoop, 'Failed due to looped symlinks'
      end
    end
  end
end
