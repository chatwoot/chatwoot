module INotify
  # Watchers monitor a single path for changes,
  # specified by {INotify::Notifier#watch event flags}.
  # A watcher is usually created via \{Notifier#watch}.
  #
  # One {Notifier} may have many {Watcher}s.
  # The Notifier actually takes care of the checking for events,
  # via \{Notifier#run #run} or \{Notifier#process #process}.
  # The main purpose of having Watcher objects
  # is to be able to disable them using \{#close}.
  class Watcher
    # The {Notifier} that this Watcher belongs to.
    #
    # @return [Notifier]
    attr_reader :notifier

    # The path that this Watcher is watching.
    #
    # @return [String]
    attr_reader :path

    # The {INotify::Notifier#watch flags}
    # specifying the events that this Watcher is watching for,
    # and potentially some options as well.
    #
    # @return [Array<Symbol>]
    attr_reader :flags

    # The id for this Watcher.
    # Used to retrieve this Watcher from {Notifier#watchers}.
    #
    # @private
    # @return [Fixnum]
    attr_reader :id

    # Calls this Watcher's callback with the given {Event}.
    #
    # @private
    # @param event [Event]
    def callback!(event)
      @callback[event]
    end

    # Disables this Watcher, so that it doesn't fire any more events.
    #
    # @raise [SystemCallError] if the watch fails to be disabled for some reason
    def close
      if Native.inotify_rm_watch(@notifier.fd, @id) == 0
        @notifier.watchers.delete(@id)
        return
      end

      raise SystemCallError.new("Failed to stop watching #{path.inspect}",
                                FFI.errno)
    end

    # Creates a new {Watcher}.
    #
    # @private
    # @see Notifier#watch
    def initialize(notifier, path, *flags, &callback)
      @notifier = notifier
      @callback = callback || proc {}
      @path = path
      @flags = flags.freeze
      @id = Native.inotify_add_watch(@notifier.fd, path.dup,
        Native::Flags.to_mask(flags))

      unless @id < 0
        @notifier.watchers[@id] = self
        return
      end

      raise SystemCallError.new(
        "Failed to watch #{path.inspect}" +
        case FFI.errno
        when Errno::EACCES::Errno; ": read access to the given file is not permitted."
        when Errno::EBADF::Errno; ": the given file descriptor is not valid."
        when Errno::EFAULT::Errno; ": path points outside of the process's accessible address space."
        when Errno::EINVAL::Errno; ": the given event mask contains no legal events; or fd is not an inotify file descriptor."
        when Errno::ENOMEM::Errno; ": insufficient kernel memory was available."
        when Errno::ENOSPC::Errno; ": The user limit on the total number of inotify watches was reached or the kernel failed to allocate a needed resource."
        else; ""
        end,
        FFI.errno)
    end
  end
end
