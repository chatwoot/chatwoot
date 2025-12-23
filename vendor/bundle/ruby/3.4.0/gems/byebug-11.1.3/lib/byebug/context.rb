# frozen_string_literal: true

require_relative "frame"
require_relative "helpers/path"
require_relative "helpers/file"
require_relative "processors/command_processor"

module Byebug
  #
  # Mantains context information for the debugger and it's the main
  # communication point between the library and the C-extension through the
  # at_breakpoint, at_catchpoint, at_tracing, at_line and at_return callbacks
  #
  class Context
    include Helpers::FileHelper

    class << self
      include Helpers::PathHelper

      attr_writer :ignored_files

      #
      # List of files byebug will ignore while debugging
      #
      def ignored_files
        @ignored_files ||=
          Byebug.mode == :standalone ? lib_files + [bin_file] : lib_files
      end

      attr_writer :interface

      def interface
        @interface ||= LocalInterface.new
      end

      attr_writer :processor

      def processor
        @processor ||= CommandProcessor
      end
    end

    #
    # Reader for the current frame
    #
    def frame
      @frame ||= Frame.new(self, 0)
    end

    #
    # Writer for the current frame
    #
    def frame=(pos)
      @frame = Frame.new(self, pos)
    end

    extend Forwardable
    def_delegators :frame, :file, :line

    #
    # Current file & line information
    #
    def location
      "#{normalize(file)}:#{line}"
    end

    #
    # Current file, line and source code information
    #
    def full_location
      return location if virtual_file?(file)

      "#{location} #{get_line(file, line)}"
    end

    #
    # Context's stack size
    #
    def stack_size
      return 0 unless backtrace

      backtrace.drop_while { |l| ignored_file?(l.first.path) }
               .take_while { |l| !ignored_file?(l.first.path) }
               .size
    end

    def interrupt
      step_into 1
    end

    #
    # Line handler
    #
    def at_line
      self.frame = 0
      return if ignored_file?(file)

      processor.at_line
    end

    #
    # Tracing handler
    #
    def at_tracing
      return if ignored_file?(file)

      processor.at_tracing
    end

    #
    # Breakpoint handler
    #
    def at_breakpoint(breakpoint)
      processor.at_breakpoint(breakpoint)
    end

    #
    # Catchpoint handler
    #
    def at_catchpoint(exception)
      processor.at_catchpoint(exception)
    end

    #
    # Return handler
    #
    def at_return(return_value)
      return if ignored_file?(file)

      processor.at_return(return_value)
    end

    #
    # End of class definition handler
    #
    def at_end
      return if ignored_file?(file)

      processor.at_end
    end

    private

    def processor
      @processor ||= self.class.processor.new(self, self.class.interface)
    end

    #
    # Tells whether a file is ignored by the debugger.
    #
    # @param path [String] filename to be checked.
    #
    def ignored_file?(path)
      self.class.ignored_files.include?(path)
    end
  end
end
