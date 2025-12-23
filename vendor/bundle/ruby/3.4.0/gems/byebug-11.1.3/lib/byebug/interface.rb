# frozen_string_literal: true

require_relative "setting"
require_relative "history"
require_relative "helpers/file"

#
# Namespace for all of byebug's code
#
module Byebug
  #
  # Main Interface class
  #
  # Contains common functionality to all implemented interfaces.
  #
  class Interface
    include Helpers::FileHelper

    attr_accessor :command_queue, :history
    attr_reader :input, :output, :error

    def initialize
      @command_queue = []
      @history = History.new
      @last_line = ""
    end

    def last_if_empty(input)
      @last_line = input.empty? ? @last_line : input
    end

    #
    # Pops a command from the input stream.
    #
    def read_command(prompt)
      return command_queue.shift unless command_queue.empty?

      read_input(prompt)
    end

    #
    # Pushes lines in +filename+ to the command queue.
    #
    def read_file(filename)
      command_queue.concat(get_lines(filename))
    end

    #
    # Reads a new line from the interface's input stream, parses it into
    # commands and saves it to history.
    #
    # @return [String] Representing something to be run by the debugger.
    #
    def read_input(prompt, save_hist = true)
      line = prepare_input(prompt)
      return unless line

      history.push(line) if save_hist

      command_queue.concat(split_commands(line))
      command_queue.shift
    end

    #
    # Reads a new line from the interface's input stream.
    #
    # @return [String] New string read or the previous string if the string
    # read now was empty.
    #
    def prepare_input(prompt)
      line = readline(prompt)
      return unless line

      last_if_empty(line)
    end

    #
    # Prints an error message to the error stream.
    #
    def errmsg(message)
      error.print("*** #{message}\n")
    end

    #
    # Prints an output message to the output stream.
    #
    def puts(message)
      output.puts(message)
    end

    #
    # Prints an output message to the output stream without a final "\n".
    #
    def print(message)
      output.print(message)
    end

    #
    # Confirms user introduced an affirmative response to the input stream.
    #
    def confirm(prompt)
      readline(prompt) == "y"
    end

    def close
    end

    #
    # Saves or clears history according to +autosave+ setting.
    #
    def autosave
      Setting[:autosave] ? history.save : history.clear
    end

    #
    # Restores history according to +autosave+ setting.
    #
    def autorestore
      history.restore if Setting[:autosave]
    end

    private

    #
    # Splits a command line of the form "cmd1 ; cmd2 ; ... ; cmdN" into an
    # array of commands: [cmd1, cmd2, ..., cmdN]
    #
    def split_commands(cmd_line)
      return [""] if cmd_line.empty?

      cmd_line.split(/;/).each_with_object([]) do |v, m|
        if m.empty? || m.last[-1] != '\\'
          m << v.strip
          next
        end

        m.last[-1, 1] = ""
        m.last << ";" << v
      end
    end
  end
end

require_relative "interfaces/local_interface"
require_relative "interfaces/script_interface"
require_relative "interfaces/remote_interface"
