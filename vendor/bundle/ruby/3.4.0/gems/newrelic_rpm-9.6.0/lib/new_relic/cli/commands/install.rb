# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'fileutils'
require 'new_relic/version'
require 'erb'

class NewRelic::Cli::Install < NewRelic::Cli::Command
  NO_LICENSE_KEY = '<PASTE LICENSE KEY HERE>'

  def self.command; 'install'; end

  # Use -h to see options.
  # When command_line_args is a hash, we are invoking directly and
  # it's treated as an options with optional string values for
  # :user, :description, :appname, :revision, :environment,
  # and :changes.
  #
  # Will throw CommandFailed exception if there's any error.
  #
  attr_reader :dest_dir, :license_key, :generated_for_user, :quiet, :src_file, :app_name
  def initialize(command_line_args = {})
    @dest_dir = nil
    super(command_line_args)
    if @dest_dir.nil?
      # Install a newrelic.yml file into the local config directory.
      if File.directory?('config')
        @dest_dir = 'config'
      else
        @dest_dir = '.'
      end
    end
    @license_key ||= NO_LICENSE_KEY
    @app_name ||= @leftover.join(' ')
    @agent_version = NewRelic::VERSION::STRING
    raise CommandFailure.new('Application name required.', @options) unless @app_name && @app_name.size > 0
  end

  def run
    dest_file = File.expand_path(@dest_dir + '/newrelic.yml')
    if File.exist?(dest_file) && !@force
      raise NewRelic::Cli::Command::CommandFailure, 'newrelic.yml file already exists.  Use --force flag to overwrite.'
    end

    File.open(dest_file, 'w') { |out| out.puts(content) }

    puts <<~EOF unless quiet

      Installed a default configuration file at
      #{dest_file}.
    EOF
    puts <<~EOF unless quiet || @license_key != NO_LICENSE_KEY

      To monitor your application in production mode, sign up for an account
      at www.newrelic.com, and replace the newrelic.yml file with the one
      you receive upon registration.
    EOF
    puts <<~EOF unless quiet

      Visit support.newrelic.com if you are experiencing installation issues.
    EOF
  end

  def content
    @src_file ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'newrelic.yml'))
    template = File.read(@src_file)
    ERB.new(template).result(binding)
  end

  private

  def options
    OptionParser.new("Usage: #{$0} #{self.class.command} [ OPTIONS] 'application name'", 40) do |o|
      o.on('-f', '--force', 'Overwrite newrelic.yml if it exists') { |e| @force = true }
      o.on('-l', '--license_key=NAME', String,
        'Use the given license key') { |e| @license_key = e }
      o.on('-d', '--destdir=name', String,
        "Write the newrelic.yml to the given directory, default is '.'") { |e| @dest_dir = e }
      yield(o) if block_given?
    end
  end
end
