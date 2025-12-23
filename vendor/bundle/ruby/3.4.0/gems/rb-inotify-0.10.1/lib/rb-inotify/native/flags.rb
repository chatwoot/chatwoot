module INotify
  module Native
    # A module containing all the inotify flags
    # to be passed to {Notifier#watch}.
    #
    # @private
    module Flags
      # File was accessed.
      IN_ACCESS = 0x00000001
      # Metadata changed.
      IN_ATTRIB = 0x00000004
      # Writtable file was closed.
      IN_CLOSE_WRITE = 0x00000008
      # File was modified.
      IN_MODIFY = 0x00000002
      # Unwrittable file closed.
      IN_CLOSE_NOWRITE = 0x00000010
      # File was opened.
      IN_OPEN = 0x00000020
      # File was moved from X.
      IN_MOVED_FROM = 0x00000040
      # File was moved to Y.
      IN_MOVED_TO = 0x00000080
      # Subfile was created.
      IN_CREATE = 0x00000100
      # Subfile was deleted.
      IN_DELETE = 0x00000200
      # Self was deleted.
      IN_DELETE_SELF = 0x00000400
      # Self was moved.
      IN_MOVE_SELF = 0x00000800

      ## Helper events.

      # Close.
      IN_CLOSE = (IN_CLOSE_WRITE | IN_CLOSE_NOWRITE)
      # Moves.
      IN_MOVE = (IN_MOVED_FROM | IN_MOVED_TO)
      # All events which a program can wait on.
      IN_ALL_EVENTS = (IN_ACCESS | IN_MODIFY | IN_ATTRIB | IN_CLOSE_WRITE |
        IN_CLOSE_NOWRITE | IN_OPEN | IN_MOVED_FROM | IN_MOVED_TO | IN_CREATE |
        IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF)


      ## Special flags.

      # Only watch the path if it is a directory.
      IN_ONLYDIR = 0x01000000
      # Do not follow a sym link.
      IN_DONT_FOLLOW = 0x02000000
      # Add to the mask of an already existing watch.
      IN_MASK_ADD = 0x20000000
      # Only send event once.
      IN_ONESHOT = 0x80000000


      ## Events sent by the kernel.

      # Backing fs was unmounted.
      IN_UNMOUNT = 0x00002000
      # Event queued overflowed.
      IN_Q_OVERFLOW = 0x00004000
      # File was ignored.
      IN_IGNORED = 0x00008000
      # Event occurred against dir.
      IN_ISDIR = 0x40000000

      ## fpathconf Macros

      # returns the maximum length of a filename in the directory path or fd that the process is allowed to create.  The corresponding macro is _POSIX_NAME_MAX.
      PC_NAME_MAX = 3

      # Converts a list of flags to the bitmask that the C API expects.
      #
      # @param flags [Array<Symbol>]
      # @return [Fixnum]
      def self.to_mask(flags)
        flags.map {|flag| const_get("IN_#{flag.to_s.upcase}")}.
          inject(0) {|mask, flag| mask | flag}
      end

      # Converts a bitmask from the C API into a list of flags.
      #
      # @param mask [Fixnum]
      # @return [Array<Symbol>]
      def self.from_mask(mask)
        constants.map {|c| c.to_s}.select do |c|
          next false unless c =~ /^IN_/
          const_get(c) & mask != 0
        end.map {|c| c.sub("IN_", "").downcase.to_sym} - [:all_events]
      end
    end
  end
end
