module SCSSLint
  # Encapsulates all communication to an output source.
  class Logger
    # Whether colored output via ANSI escape sequences is enabled.
    # @return [true,false]
    attr_accessor :color_enabled

    # Creates a logger which outputs nothing.
    # @return [SCSSLint::Logger]
    def self.silent
      new(File.open('/dev/null', 'w'))
    end

    # Creates a new {SCSSLint::Logger} instance.
    #
    # @param out [IO] the output destination.
    def initialize(out)
      @out = out
    end

    # Print the specified output.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def log(output, newline = true)
      @out.print(output)
      @out.print("\n") if newline
    end

    # Print the specified output in a color indicative of error.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def error(output, newline = true)
      log(red(output), newline)
    end

    # Print the specified output in a bold face and color indicative of error.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def bold_error(output, newline = true)
      log(bold_red(output), newline)
    end

    # Print the specified output in a color indicative of success.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def success(output, newline = true)
      log(green(output), newline)
    end

    # Print the specified output in a color indicative of a warning.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def warning(output, newline = true)
      log(yellow(output), newline)
    end

    # Print the specified output in a color indicating information.
    # If output destination is not a TTY, behaves the same as {#log}.
    #
    # @param output [String] the output to send
    # @param newline [true,false] whether to append a newline
    def info(output, newline = true)
      log(cyan(output), newline)
    end

    # Print a blank line.
    def newline
      log('')
    end

    # Mark the specified output in bold face.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def bold(output)
      color('1', output)
    end

    # Mark the specified output in bold red.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def bold_red(output)
      color('1;31', output)
    end

    # Mark the specified output in red.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def red(output)
      color(31, output)
    end

    # Mark the specified output in green.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def green(output)
      color(32, output)
    end

    # Mark the specified output in yellow.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def yellow(output)
      color(33, output)
    end

    # Mark the specified output in magenta.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def magenta(output)
      color(35, output)
    end

    # Mark the specified output in cyan.
    # If output destination is not a TTY, this is a noop.
    #
    # @param output [String] the output to format
    def cyan(output)
      color(36, output)
    end

    # Whether this logger is outputting to a TTY.
    #
    # @return [true,false]
    def tty?
      @out.respond_to?(:tty?) && @out.tty?
    end

  private

    def color(code, output)
      color_enabled ? "\033[#{code}m#{output}\033[0m" : output
    end
  end
end
