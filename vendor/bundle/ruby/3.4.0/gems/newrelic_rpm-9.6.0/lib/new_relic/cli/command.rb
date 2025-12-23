# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'optparse'

# Run the command given by the first argument.  Right
# now all we have is deployments. We hope to have other
# kinds of events here later.
$LOAD_PATH << "#{File.dirname(__FILE__)}/.."
module NewRelic
  module Cli
    class Command
      attr_accessor :leftover
      # Capture a failure to execute the command.
      class CommandFailure < StandardError
        attr_reader :options
        def initialize(message, opt_parser = nil)
          super(message)
          @options = opt_parser
        end
      end

      def info(message)
        STDOUT.puts message
      end

      def err(message)
        STDERR.puts message
      end

      def initialize(command_line_args)
        if Hash === command_line_args
          # command line args is an options hash
          command_line_args.each do |key, value|
            instance_variable_set("@#{key}", value.to_s) if value
          end
        else
          # parse command line args.  Throw an exception on a bad arg.
          @options = options do |opts|
            opts.on('-h', 'Show this help') { raise CommandFailure, opts.to_s }
          end
          @leftover = @options.parse(command_line_args)
        end
      rescue OptionParser::ParseError => e
        raise CommandFailure.new(e.message, @options)
      end

      @commands = []
      def self.inherited(subclass)
        @commands << subclass
      end

      cmds = File.expand_path(File.join(File.dirname(__FILE__), 'commands', '*.rb'))
      Dir[cmds].each { |command| require command }

      def self.run
        @command_names = @commands.map { |c| c.command }

        extra = []
        options = ARGV.options do |opts|
          script_name = File.basename($0)
          # TODO: MAJOR VERSION - remove newrelic_cmd, deprecated since version 2.13
          if /newrelic_cmd$/.match?(script_name)
            $stdout.puts "warning: the 'newrelic_cmd' script has been renamed 'newrelic'"
            script_name = 'newrelic'
          end
          opts.banner = "Usage: #{script_name} [ #{@command_names.join(' | ')} ] [options]"
          opts.separator("use '#{script_name} <command> -h' to see detailed command options")
          opts
        end
        extra = options.order!
        command = extra.shift
        # just make it a little easier on them
        command = 'deployments' if command.include?('deploy')
        if command.nil?
          STDERR.puts options
        elsif !@command_names.include?(command)
          STDERR.puts "Unrecognized command: #{command}"
          STDERR.puts options
        else
          command_class = @commands.find { |c| c.command == command }
          command_class.new(extra).run
        end
      rescue OptionParser::InvalidOption => e
        raise NewRelic::Cli::Command::CommandFailure, e.message
      end
    end
  end
end
