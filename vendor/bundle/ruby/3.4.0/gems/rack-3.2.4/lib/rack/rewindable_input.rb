# -*- encoding: binary -*-
# frozen_string_literal: true

require 'tempfile'

require_relative 'constants'

module Rack
  # Class which can make any IO object rewindable, including non-rewindable ones. It does
  # this by buffering the data into a tempfile, which is rewindable.
  #
  # Don't forget to call #close when you're done. This frees up temporary resources that
  # RewindableInput uses, though it does *not* close the original IO object.
  class RewindableInput
    # Makes rack.input rewindable, for compatibility with applications and middleware
    # designed for earlier versions of Rack (where rack.input was required to be
    # rewindable).
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if (input = env[RACK_INPUT])
          env[RACK_INPUT] = RewindableInput.new(input)
        end

        @app.call(env)
      end
    end

    def initialize(io)
      @io = io
      @rewindable_io = nil
      @unlinked = false
    end

    def gets
      make_rewindable unless @rewindable_io
      @rewindable_io.gets
    end

    def read(*args)
      make_rewindable unless @rewindable_io
      @rewindable_io.read(*args)
    end

    def each(&block)
      make_rewindable unless @rewindable_io
      @rewindable_io.each(&block)
    end

    def rewind
      make_rewindable unless @rewindable_io
      @rewindable_io.rewind
    end

    def size
      make_rewindable unless @rewindable_io
      @rewindable_io.size
    end

    # Closes this RewindableInput object without closing the originally
    # wrapped IO object. Cleans up any temporary resources that this RewindableInput
    # has created.
    #
    # This method may be called multiple times. It does nothing on subsequent calls.
    def close
      if @rewindable_io
        if @unlinked
          @rewindable_io.close
        else
          @rewindable_io.close!
        end
        @rewindable_io = nil
      end
    end

    private

    def make_rewindable
      # Buffer all data into a tempfile. Since this tempfile is private to this
      # RewindableInput object, we chmod it so that nobody else can read or write
      # it. On POSIX filesystems we also unlink the file so that it doesn't
      # even have a file entry on the filesystem anymore, though we can still
      # access it because we have the file handle open.
      @rewindable_io = Tempfile.new('RackRewindableInput')
      @rewindable_io.chmod(0000)
      @rewindable_io.set_encoding(Encoding::BINARY)
      @rewindable_io.binmode
      # :nocov:
      if filesystem_has_posix_semantics?
        raise 'Unlink failed. IO closed.' if @rewindable_io.closed?
        @unlinked = true
      end
      # :nocov:

      buffer = "".dup
      while @io.read(1024 * 4, buffer)
        entire_buffer_written_out = false
        while !entire_buffer_written_out
          written = @rewindable_io.write(buffer)
          entire_buffer_written_out = written == buffer.bytesize
          if !entire_buffer_written_out
            buffer.slice!(0 .. written - 1)
          end
        end
      end
      @rewindable_io.rewind
    end

    def filesystem_has_posix_semantics?
      RUBY_PLATFORM !~ /(mswin|mingw|cygwin|java)/
    end
  end
end
