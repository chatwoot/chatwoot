require 'thread'

module INotify
  # Notifier wraps a single instance of inotify.
  # It's possible to have more than one instance,
  # but usually unnecessary.
  #
  # @example
  #   # Create the notifier
  #   notifier = INotify::Notifier.new
  #
  #   # Run this callback whenever the file path/to/foo.txt is read
  #   notifier.watch("path/to/foo.txt", :access) do
  #     puts "Foo.txt was accessed!"
  #   end
  #
  #   # Watch for any file in the directory being deleted
  #   # or moved out of the directory.
  #   notifier.watch("path/to/directory", :delete, :moved_from) do |event|
  #     # The #name field of the event object contains the name of the affected file
  #     puts "#{event.name} is no longer in the directory!"
  #   end
  #
  #   # Nothing happens until you run the notifier!
  #   notifier.run
  class Notifier
    # A list of directories that should never be recursively watched.
    #
    # * Files in `/dev/fd` sometimes register as directories, but are not enumerable.
    RECURSIVE_BLACKLIST = %w[/dev/fd]

    # A hash from {Watcher} ids to the instances themselves.
    #
    # @private
    # @return [{Fixnum => Watcher}]
    attr_reader :watchers

    # The underlying file descriptor for this notifier.
    # This is a valid OS file descriptor, and can be used as such
    # (except under JRuby -- see \{#to\_io}).
    #
    # @return [Fixnum]
    def fd
      @handle.fileno
    end

    # Creates a new {Notifier}.
    #
    # @return [Notifier]
    # @raise [SystemCallError] if inotify failed to initialize for some reason
    def initialize
      @running = Mutex.new
      @pipe = IO.pipe
      # JRuby shutdown sometimes runs IO finalizers before all threads finish.
      if RUBY_ENGINE == 'jruby'
        @pipe[0].autoclose = false
        @pipe[1].autoclose = false
      end

      @watchers = {}

      fd = Native.inotify_init
      unless fd < 0
        @handle = IO.new(fd)
        @handle.autoclose = false if RUBY_ENGINE == 'jruby'
        return
      end

      raise SystemCallError.new(
        "Failed to initialize inotify" +
        case FFI.errno
        when Errno::EMFILE::Errno; ": the user limit on the total number of inotify instances has been reached."
        when Errno::ENFILE::Errno; ": the system limit on the total number of file descriptors has been reached."
        when Errno::ENOMEM::Errno; ": insufficient kernel memory is available."
        else; ""
        end,
        FFI.errno)
    end

    # Returns a Ruby IO object wrapping the underlying file descriptor.
    # Since this file descriptor is fully functional (except under JRuby),
    # this IO object can be used in any way a Ruby-created IO object can.
    # This includes passing it to functions like `#select`.
    #
    # Note that this always returns the same IO object.
    # Creating lots of IO objects for the same file descriptor
    # can cause some odd problems.
    #
    # **This is not supported under JRuby**.
    # JRuby currently doesn't use native file descriptors for the IO object,
    # so we can't use this file descriptor as a stand-in.
    #
    # @return [IO] An IO object wrapping the file descriptor
    # @raise [NotImplementedError] if this is being called in JRuby
    def to_io
      @handle
    end

    # Watches a file or directory for changes,
    # calling the callback when there are.
    # This is only activated once \{#process} or \{#run} is called.
    #
    # **Note that by default, this does not recursively watch subdirectories
    # of the watched directory**.
    # To do so, use the `:recursive` flag.
    #
    # ## Flags
    #
    # `:access`
    # : A file is accessed (that is, read).
    #
    # `:attrib`
    # : A file's metadata is changed (e.g. permissions, timestamps, etc).
    #
    # `:close_write`
    # : A file that was opened for writing is closed.
    #
    # `:close_nowrite`
    # : A file that was not opened for writing is closed.
    #
    # `:modify`
    # : A file is modified.
    #
    # `:open`
    # : A file is opened.
    #
    # ### Directory-Specific Flags
    #
    # These flags only apply when a directory is being watched.
    #
    # `:moved_from`
    # : A file is moved out of the watched directory.
    #
    # `:moved_to`
    # : A file is moved into the watched directory.
    #
    # `:create`
    # : A file is created in the watched directory.
    #
    # `:delete`
    # : A file is deleted in the watched directory.
    #
    # `:delete_self`
    # : The watched file or directory itself is deleted.
    #
    # `:move_self`
    # : The watched file or directory itself is moved.
    #
    # ### Helper Flags
    #
    # These flags are just combinations of the flags above.
    #
    # `:close`
    # : Either `:close_write` or `:close_nowrite` is activated.
    #
    # `:move`
    # : Either `:moved_from` or `:moved_to` is activated.
    #
    # `:all_events`
    # : Any event above is activated.
    #
    # ### Options Flags
    #
    # These flags don't actually specify events.
    # Instead, they specify options for the watcher.
    #
    # `:onlydir`
    # : Only watch the path if it's a directory.
    #
    # `:dont_follow`
    # : Don't follow symlinks.
    #
    # `:mask_add`
    # : Add these flags to the pre-existing flags for this path.
    #
    # `:oneshot`
    # : Only send the event once, then shut down the watcher.
    #
    # `:recursive`
    # : Recursively watch any subdirectories that are created.
    #   Note that this is a feature of rb-inotify,
    #   rather than of inotify itself, which can only watch one level of a directory.
    #   This means that the {Event#name} field
    #   will contain only the basename of the modified file.
    #   When using `:recursive`, {Event#absolute_name} should always be used.
    #
    # @param path [String] The path to the file or directory
    # @param flags [Array<Symbol>] Which events to watch for
    # @yield [event] A block that will be called
    #   whenever one of the specified events occur
    # @yieldparam event [Event] The Event object containing information
    #   about the event that occured
    # @return [Watcher] A Watcher set up to watch this path for these events
    # @raise [SystemCallError] if the file or directory can't be watched,
    #   e.g. if the file isn't found, read access is denied,
    #   or the flags don't contain any events
    def watch(path, *flags, &callback)
      return Watcher.new(self, path, *flags, &callback) unless flags.include?(:recursive)

      dir = Dir.new(path)

      dir.each do |base|
        d = File.join(path, base)
        binary_d = d.respond_to?(:force_encoding) ? d.dup.force_encoding('BINARY') : d
        next if binary_d =~ /\/\.\.?$/ # Current or parent directory
        next if RECURSIVE_BLACKLIST.include?(d)
        next if flags.include?(:dont_follow) && File.symlink?(d)
        next if !File.directory?(d)

        watch(d, *flags, &callback)
      end

      dir.close

      rec_flags = [:create, :moved_to]
      return watch(path, *((flags - [:recursive]) | rec_flags)) do |event|
        callback.call(event) if flags.include?(:all_events) || !(flags & event.flags).empty?
        next if (rec_flags & event.flags).empty? || !event.flags.include?(:isdir)
        begin
          watch(event.absolute_name, *flags, &callback)
        rescue Errno::ENOENT
          # If the file has been deleted since the glob was run, we don't want to error out.
        end
      end
    end

    # Starts the notifier watching for filesystem events.
    # Blocks until \{#stop} is called.
    #
    # @see #process
    def run
      @running.synchronize do
        Thread.current[:INOTIFY_RUN_THREAD] = true
        @stop = false

        process until @stop
      end
    ensure
      Thread.current[:INOTIFY_RUN_THREAD] = false
    end

    # Stop watching for filesystem events.
    # That is, if we're in a \{#run} loop,
    # exit out as soon as we finish handling the events.
    def stop
      @stop = true
      @pipe.last.write "."

      unless Thread.current[:INOTIFY_RUN_THREAD]
        @running.synchronize do
          # no-op: we just needed to wait until the lock was available
        end
      end
    end

    # Blocks until there are one or more filesystem events
    # that this notifier has watchers registered for.
    # Once there are events, the appropriate callbacks are called
    # and this function returns.
    #
    # @see #run
    def process
      read_events.each do |event|
        event.callback!
        event.flags.include?(:ignored) && event.notifier.watchers.delete(event.watcher_id)
      end
    end

    # Close the notifier.
    #
    # @raise [SystemCallError] if closing the underlying file descriptor fails.
    def close
      stop
      @handle.close
      @watchers.clear
    end

    # Blocks until there are one or more filesystem events that this notifier
    # has watchers registered for. Once there are events, returns their {Event}
    # objects.
    #
    # This can return an empty list if the watcher was closed elsewhere.
    #
    # {#run} or {#process} are ususally preferable to calling this directly.
    def read_events
      size = Native::Event.size + Native.fpathconf(fd, Native::Flags::PC_NAME_MAX) + 1
      tries = 1

      begin
        data = readpartial(size)
      rescue SystemCallError => er
        # EINVAL means that there's more data to be read
        # than will fit in the buffer size
        raise er unless er.errno == Errno::EINVAL::Errno && tries < 5
        size *= 2
        tries += 1
        retry
      end
      return [] if data.nil?

      events = []
      cookies = {}
      while event = Event.consume(data, self)
        events << event
        next if event.cookie == 0
        cookies[event.cookie] ||= []
        cookies[event.cookie] << event
      end
      cookies.each {|c, evs| evs.each {|ev| ev.related.replace(evs - [ev]).freeze}}
      events
    end

    private

    # Same as IO#readpartial, or as close as we need.
    def readpartial(size)
      readable, = select([@handle, @pipe.first])
      return nil if readable.include?(@pipe.first)
      @handle.readpartial(size)
    rescue Errno::EBADF
      # If the IO has already been closed, reading from it will cause
      # Errno::EBADF.
      nil
    end
  end
end
