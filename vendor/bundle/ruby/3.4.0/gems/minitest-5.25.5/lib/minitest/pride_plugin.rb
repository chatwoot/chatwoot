require "minitest"

module Minitest
  def self.plugin_pride_options opts, _options # :nodoc:
    opts.on "-p", "--pride", "Pride. Show your testing pride!" do
      PrideIO.pride!
    end
  end

  def self.plugin_pride_init options # :nodoc:
    return unless PrideIO.pride?

    klass = ENV["TERM"] =~ /^xterm|-(?:256color|direct)$/ ? PrideLOL : PrideIO
    io    = klass.new options[:io]

    self.reporter.reporters.grep(Minitest::Reporter).each do |rep|
      rep.io = io if rep.io.tty?
    end
  end

  ##
  # Show your testing pride!

  class PrideIO
    ##
    # Activate the pride plugin. Called from both -p option and minitest/pride

    def self.pride!
      @pride = true
    end

    ##
    # Are we showing our testing pride?

    def self.pride?
      @pride ||= false
    end

    # Start an escape sequence
    ESC = "\e["

    # End the escape sequence
    NND = "#{ESC}0m"

    # The IO we're going to pipe through.
    attr_reader :io

    def initialize io # :nodoc:
      @io = io
      # stolen from /System/Library/Perl/5.10.0/Term/ANSIColor.pm
      # also reference https://en.wikipedia.org/wiki/ANSI_escape_code
      @colors ||= (31..36).to_a
      @size   = @colors.size
      @index  = 0
    end

    ##
    # Wrap print to colorize the output.

    def print o
      case o
      when ".", "S" then
        io.print pride o
      when "E", "F" then
        io.print "#{ESC}41m#{ESC}37m#{o}#{NND}"
      else
        io.print o
      end
    end

    def puts *o # :nodoc:
      o.map! { |s|
        s.to_s.sub("Finished") {
          @index = 0
          "Fabulous run".chars.map { |c| pride(c) }.join
        }
      }

      io.puts(*o)
    end

    ##
    # Color a string.

    def pride string
      string = "*" if string == "."
      c = @colors[@index % @size]
      @index += 1
      "#{ESC}#{c}m#{string}#{NND}"
    end

    def method_missing msg, *args # :nodoc:
      io.send(msg, *args)
    end
  end

  ##
  # If you thought the PrideIO was colorful...
  #
  # (Inspired by lolcat, but with clean math)

  class PrideLOL < PrideIO
    PI_3 = Math::PI / 3 # :nodoc:

    def initialize io # :nodoc:
      # walk red, green, and blue around a circle separated by equal thirds.
      #
      # To visualize, type this into wolfram-alpha:
      #
      #   plot (3*sin(x)+3), (3*sin(x+2*pi/3)+3), (3*sin(x+4*pi/3)+3)

      @colors = Array.new(6 * 7) { |n|
        n *= 1.0 / 3
        r  = (3 * Math.sin(n           ) + 3).to_i
        g  = (3 * Math.sin(n + 4 * PI_3) + 3).to_i
        b  = (3 * Math.sin(n + 2 * PI_3) + 3).to_i

        # Then we take rgb and encode them in a single number using
        # base 6, shifted by 16 for the base 16 ansi colors.
        36 * r + 6 * g + b + 16
      }.rotate(4) # puts "red" first

      super
    end

    ##
    # Make the string even more colorful. Damnit.

    def pride string
      c = @colors[@index % @size]
      @index += 1
      "#{ESC}38;5;#{c}m#{string}#{NND}"
    end
  end
end
