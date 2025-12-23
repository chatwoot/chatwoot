# frozen_string_literal: true

require "optparse"

module Launchy
  # Internal: Command line interface for Launchy
  #
  class Cli
    attr_reader :options

    def initialize
      @options = {}
    end

    def parser
      @parser ||= OptionParser.new do |op|
        op.banner = "Usage: launchy [options] thing-to-launch"

        op.separator ""
        op.separator "Launch Options:"

        op.on("-a", "--application APPLICATION",
              "Explicitly specify the application class to use in the launch") do |app|
          @options[:application] = app
        end

        op.on("-d", "--debug",
              "Force debug. Output lots of information.") do |_d|
          @options[:debug] = true
        end

        op.on("-n", "--dry-run", "Don't launchy, print the command to be executed on stdout") do |_x|
          @options[:dry_run] = true
        end

        op.on("-o", "--host-os HOST_OS",
              "Force launchy to behave as if it was on a particular host os.") do |os|
          @options[:host_os] = os
        end

        op.separator ""
        op.separator "Standard Options:"

        op.on("-h", "--help", "Print this message.") do |_h|
          $stdout.puts op.to_s
          exit 0
        end

        op.on("-v", "--version", "Output the version of Launchy") do |_v|
          $stdout.puts "Launchy version #{Launchy::VERSION}"
          exit 0
        end
      end
    end

    def parse(argv, _env)
      parser.parse!(argv)
      true
    rescue ::OptionParser::ParseError => e
      error_output(e)
    end

    def good_run(argv, env)
      return false unless parse(argv, env)

      Launchy.open(argv.shift, options) { |e| error_output(e) }
      true
    end

    def error_output(error)
      $stderr.puts "ERROR: #{error}"
      Launchy.log "ERROR: #{error}"
      error.backtrace.each do |bt|
        Launchy.log bt
      end
      $stderr.puts "Try `#{parser.program_name} --help' for more information."
      false
    end

    def run(argv = ARGV, env = ENV)
      exit 1 unless good_run(argv, env)
    end
  end
end
