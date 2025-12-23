# frozen_string_literal: true

require "English"
require "addressable/uri"
require "shellwords"
require "stringio"

#
# The entry point into Launchy. This is the sole supported public API.
#
#   Launchy.open( uri, options = {} )
#
# The currently defined global options are:
#
#   :debug        Turn on debugging output
#   :application  Explicitly state what application class is going to be used.
#                 This must be a child class of Launchy::Application
#   :host_os      Explicitly state what host operating system to pretend to be
#   :dry_run      Do nothing and print the command that would be executed on $stdout
#
# Other options may be used, and those will be passed directly to the
# application class
#
module Launchy
  class << self
    #
    # Launch an application for the given uri string
    #
    def open(uri_s, options = {})
      leftover = extract_global_options(options)
      uri = string_to_uri(uri_s)
      if (name = options[:application])
        app = app_for_name(name)
      end

      app = app_for_uri(uri) if app.nil?

      app.new.open(uri, leftover)
    rescue Launchy::Error => e
      raise e
    rescue StandardError => e
      msg = "Failure in opening uri #{uri_s.inspect} with options #{options.inspect}: #{e}"
      raise Launchy::Error, msg
    ensure
      if $ERROR_INFO && block_given?
        yield $ERROR_INFO

        # explicitly return here to swallow the errors if there was an error
        # and we yielded to the block
        # rubocop:disable Lint/EnsureReturn
        return
        # rubocop:enable Lint/EnsureReturn
      end
    end

    def app_for_uri(uri)
      Launchy::Application.handling(uri)
    end

    def app_for_name(name)
      Launchy::Application.for_name(name)
    rescue Launchy::ApplicationNotFoundError
      nil
    end

    def app_for_uri_string(str)
      app_for_uri(string_to_uri(str))
    end

    def string_to_uri(str)
      str = str.to_s
      uri = Addressable::URI.parse(str)
      Launchy.log "URI parsing pass 1 : #{str} -> #{uri.to_hash}"
      unless uri.scheme
        uri = Addressable::URI.heuristic_parse(str)
        Launchy.log "URI parsing pass 2 : #{str} -> #{uri.to_hash}"
      end
      raise Launchy::ArgumentError, "Invalid URI given: #{str.inspect}" unless uri

      uri
    end

    def reset_global_options
      Launchy.debug       = false
      Launchy.application = nil
      Launchy.host_os     = nil
      Launchy.dry_run     = false
      Launchy.path        = ENV.fetch("PATH", nil)
    end

    def extract_global_options(options)
      leftover = options.dup
      Launchy.debug        = leftover.delete(:debug) || ENV.fetch("LAUNCHY_DEBUG", nil)
      Launchy.application  = leftover.delete(:application) || ENV.fetch("LAUNCHY_APPLICATION", nil)
      Launchy.host_os      = leftover.delete(:host_os) || ENV.fetch("LAUNCHY_HOST_OS", nil)
      Launchy.dry_run      = leftover.delete(:dry_run) || ENV.fetch("LAUNCHY_DRY_RUN", nil)
    end

    def debug=(enabled)
      @debug = to_bool(enabled)
    end

    # we may do logging before a call to 'open', hence the need to check
    # LAUNCHY_DEBUG here
    def debug?
      @debug || to_bool(ENV.fetch("LAUNCHY_DEBUG", nil))
    end

    def application=(app)
      @application = app
    end

    def application
      @application || ENV.fetch("LAUNCHY_APPLICATION", nil)
    end

    def host_os=(host_os)
      @host_os = host_os
    end

    def host_os
      @host_os || ENV.fetch("LAUNCHY_HOST_OS", nil)
    end

    def dry_run=(dry_run)
      @dry_run = to_bool(dry_run)
    end

    def dry_run?
      @dry_run || to_bool(ENV.fetch("LAUNCHY_DRY_RUN", nil))
    end

    def bug_report_message
      "Please rerun with environment variable LAUNCHY_DEBUG=true or the '-d' commandline option and file a bug at https://github.com/copiousfreetime/launchy/issues/new"
    end

    def log(msg)
      $stderr.puts "LAUNCHY_DEBUG: #{msg}" if Launchy.debug?
    end

    def path
      @path
    end

    def path=(path)
      @path = path
    end

    private

    def to_bool(arg)
      if arg.is_a? String
        arg == "true"
      else
        arg.is_a? TrueClass
      end
    end
  end

  # Iniitialize the global options to sane defaults during parse time.
  Launchy.reset_global_options
end

require "launchy/version"
require "launchy/argv"
require "launchy/cli"
require "launchy/descendant_tracker"
require "launchy/error"
require "launchy/application"
require "launchy/detect"
require "launchy/runner"
