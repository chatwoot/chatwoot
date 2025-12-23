# coding: utf-8

#--
# terminal.rb
#
#  Originally created by James Edward Gray II on 2006-06-14 as
#  system_extensions.rb.
#  Copyright 2006 Gray Productions. All rights reserved.
#
#  This is Free Software.  See LICENSE and COPYING for details.

require "highline/compatibility"

class HighLine
  # Basic Terminal class which HighLine will direct
  # input and output to.
  # The specialized Terminals all decend from this HighLine::Terminal class
  class Terminal
    # Probe for and return a suitable Terminal instance
    # @param input [IO] input stream
    # @param output [IO] output stream
    def self.get_terminal(input, output)
      # First of all, probe for io/console
      begin
        require "io/console"
        require "highline/terminal/io_console"
        terminal = HighLine::Terminal::IOConsole.new(input, output)
      rescue LoadError
        require "highline/terminal/unix_stty"
        terminal = HighLine::Terminal::UnixStty.new(input, output)
      end

      terminal.initialize_system_extensions
      terminal
    end

    # @return [IO] input stream
    attr_reader :input

    # @return [IO] output stream
    attr_reader :output

    # Creates a terminal instance based on given input and output streams.
    # @param input [IO] input stream
    # @param output [IO] output stream
    def initialize(input, output)
      @input  = input
      @output = output
    end

    # An initialization callback.
    # It is called by {.get_terminal}.
    def initialize_system_extensions; end

    # @return [Array<Integer, Integer>] two value terminal
    #   size like [columns, lines]
    def terminal_size
      [80, 24]
    end

    # Enter Raw No Echo mode.
    def raw_no_echo_mode; end

    # Yieds a block to be executed in Raw No Echo mode and
    # then restore the terminal state.
    def raw_no_echo_mode_exec
      raw_no_echo_mode
      yield
    ensure
      restore_mode
    end

    # Restore terminal to its default mode
    def restore_mode; end

    # Get one character from the terminal
    # @return [String] one character
    def get_character; end # rubocop:disable Naming/AccessorMethodName

    # Get one line from the terminal and format accordling.
    # Use readline if question has readline mode set.
    # @param question [HighLine::Question]
    # @param highline [HighLine]
    def get_line(question, highline)
      raw_answer =
        if question.readline
          get_line_with_readline(question, highline)
        else
          get_line_default(highline)
        end

      question.format_answer(raw_answer)
    end

    # Get one line using #readline_read
    # @param (see #get_line)
    def get_line_with_readline(question, highline)
      require "readline" # load only if needed

      raw_answer = readline_read(question)

      if !raw_answer && highline.track_eof?
        raise EOFError, "The input stream is exhausted."
      end

      raw_answer || ""
    end

    # Use readline to read one line
    # @param question [HighLine::Question] question from where to get
    #   autocomplete candidate strings
    def readline_read(question)
      # prep auto-completion
      unless question.selection.empty?
        Readline.completion_proc = lambda do |str|
          question.selection.grep(/\A#{Regexp.escape(str)}/)
        end
      end

      # work-around ugly readline() warnings
      old_verbose = $VERBOSE
      $VERBOSE    = nil

      raw_answer  = run_preserving_stty do
        Readline.readline("", true)
      end

      $VERBOSE = old_verbose

      raw_answer
    end

    # Get one line from terminal using default #gets method.
    # @param highline (see #get_line)
    def get_line_default(highline)
      raise EOFError, "The input stream is exhausted." if highline.track_eof? &&
                                                          highline.input.eof?
      highline.input.gets
    end

    # @!group Enviroment queries

    # Running on JRuby?
    def jruby?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    end

    # Running on Rubinius?
    def rubinius?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
    end

    # Running on Windows?
    def windows?
      defined?(RUBY_PLATFORM) && (RUBY_PLATFORM =~ /mswin|mingw|cygwin/)
    end

    # @!endgroup

    # Returns the class name as String. Useful for debuggin.
    # @return [String] class name. Ex: "HighLine::Terminal::IOConsole"
    def character_mode
      self.class.name
    end

    private

    # Yield a block using stty shell commands to preserve the terminal state.
    def run_preserving_stty
      save_stty
      yield
    ensure
      restore_stty
    end

    # Saves terminal state using shell stty command.
    def save_stty
      @stty_save = begin
                     `stty -g`.chomp
                   rescue StandardError
                     nil
                   end
    end

    # Restores terminal state using shell stty command.
    def restore_stty
      system("stty", @stty_save) if @stty_save
    end
  end
end
