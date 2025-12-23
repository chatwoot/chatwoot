# frozen_string_literal: true

require "optparse"
require "English"
require_relative "core"
require_relative "version"
require_relative "helpers/bin"
require_relative "helpers/parse"
require_relative "helpers/string"
require_relative "option_setter"
require_relative "processors/control_processor"

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
    include Helpers::BinHelper
    include Helpers::ParseHelper
    include Helpers::StringHelper

    #
    # Special working modes that don't actually start the debugger.
    #
    attr_reader :help, :version, :remote

    #
    # Signals that we should exit after the debugged program is finished.
    #
    attr_accessor :quit

    #
    # Signals that we should stop before program starts
    #
    attr_accessor :stop

    #
    # Signals that we should run rc scripts before program starts
    #
    attr_writer :init_script

    #
    # @param stop [Boolean] Whether the runner should stop right before
    # starting the program.
    #
    # @param quit [Boolean] Whether the runner should quit right after
    # finishing the program.
    #
    def initialize(stop = true, quit = true)
      @stop = stop
      @quit = quit
    end

    def help=(text)
      @help ||= text

      interface.puts("#{text}\n")
    end

    def version=(number)
      @version ||= number

      interface.puts prettify <<-VERSION
        Running byebug #{number}
      VERSION
    end

    def remote=(host_and_port)
      @remote ||= Byebug.parse_host_and_port(host_and_port)

      Byebug.start_client(*@remote)
    end

    def init_script
      defined?(@init_script) ? @init_script : true
    end

    #
    # Usage banner.
    #
    def banner
      prettify <<-BANNER
        byebug #{Byebug::VERSION}

        Usage: byebug [options] <script.rb> -- <script.rb parameters>
      BANNER
    end

    #
    # Starts byebug to debug a program.
    #
    def run
      Byebug.mode = :standalone

      option_parser.order!($ARGV)
      return if non_script_option? || error_in_script?

      $PROGRAM_NAME = program

      Byebug.run_init_script if init_script

      loop do
        debug_program

        break if quit

        ControlProcessor.new(nil, interface).process_commands
      end
    end

    def interface
      @interface ||= Context.interface
    end

    #
    # Processes options passed from the command line.
    #
    def option_parser
      @option_parser ||= OptionParser.new(banner, 25) do |opts|
        opts.banner = banner

        OptionSetter.new(self, opts).setup
      end
    end

    def program
      @program ||= begin
                     candidate = which($ARGV.shift)

                     if [which("ruby"), RbConfig.ruby].include?(candidate)
                       which($ARGV.shift)
                     else
                       candidate
                     end
                   end
    end

    #
    # An option that doesn't need a script specified was given
    #
    def non_script_option?
      version || help || remote
    end

    #
    # There is an error with the specified script
    #
    def error_in_script?
      no_script? || non_existing_script? || invalid_script?
    end

    #
    # No script to debug specified
    #
    def no_script?
      return false unless $ARGV.empty?

      print_error("You must specify a program to debug")
      true
    end

    #
    # Extracts debugged program from command line args.
    #
    def non_existing_script?
      return false if program

      print_error("The script doesn't exist")
      true
    end

    #
    # Checks the debugged script has correct syntax
    #
    def invalid_script?
      return false if syntax_valid?(File.read(program))

      print_error("The script has incorrect syntax")
      true
    end

    #
    # Debugs a script only if syntax checks okay.
    #
    def debug_program
      error = Byebug.debug_load(program, stop)
      puts "#{error}\n#{error.backtrace}" if error
    end

    #
    # Prints an error message and a help string
    #
    def print_error(msg)
      interface.errmsg(msg)
      interface.puts(option_parser.help)
    end
  end
end
