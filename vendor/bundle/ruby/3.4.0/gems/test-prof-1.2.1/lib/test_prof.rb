# frozen_string_literal: true

require "fileutils"
require "logger"

require "test_prof/version"
require "test_prof/logging"
require "test_prof/utils"

# Ruby applications tests profiling tools.
#
# Contains tools to analyze factories usage, integrate with Ruby profilers,
# profile your examples using ActiveSupport notifications (if any) and
# statically analyze your code with custom RuboCop cops.
#
# Example usage:
#
#   require 'test_prof'
#
#   # Activate a tool by providing environment variable, e.g.
#   TEST_RUBY_PROF=1 rspec ...
#
#   # or manually in your code
#   TestProf::RubyProf.run
#
# See other modules for more examples.
module TestProf
  class << self
    include Logging

    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    # Returns true if we're inside RSpec
    def rspec?
      defined?(RSpec::Core)
    end

    # Returns true if we're inside Minitest
    def minitest?
      defined?(Minitest)
    end

    # Returns true if Spring is used and not disabled
    def spring?
      # See https://github.com/rails/spring/blob/577cf01f232bb6dbd0ade7df2df2ac209697e741/lib/spring/binstub.rb
      disabled = ENV["DISABLE_SPRING"]
      defined?(::Spring::Application) && (disabled.nil? || disabled.empty? || disabled == "0")
    end

    # Returns the current process time
    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Require gem and shows a custom
    # message if it fails to load
    def require(gem_name, msg = nil)
      Kernel.require gem_name
      block_given? ? yield : true
    rescue LoadError
      log(:error, msg) if msg
      false
    end

    # Run block only if provided env var is present and
    # equal to the provided value (if any).
    # Contains workaround for applications using Spring.
    def activate(env_var, val = nil)
      if spring?
        notify_spring_detected
        ::Spring.after_fork do
          activate!(env_var, val) do
            notify_spring_activate env_var
            yield
          end
        end
      else
        activate!(env_var, val) { yield }
      end
    end

    # Return absolute path to asset
    def asset_path(filename)
      ::File.expand_path(filename, ::File.join(::File.dirname(__FILE__), "..", "assets"))
    end

    # Return a path to store artifact
    def artifact_path(filename)
      create_artifact_dir

      with_timestamps(
        ::File.join(
          config.output_dir,
          with_report_suffix(
            filename
          )
        )
      )
    end

    def create_artifact_dir
      FileUtils.mkdir_p(config.output_dir)[0]
    end

    private

    def activate!(env_var, val)
      yield if ENV[env_var] && (val.nil? || val === ENV[env_var])
    end

    def with_timestamps(path)
      return path unless config.timestamps?
      timestamps = "-#{now.to_i}"
      "#{path.sub(/\.\w+$/, "")}#{timestamps}#{::File.extname(path)}"
    end

    def with_report_suffix(path)
      return path if config.report_suffix.nil?

      "#{path.sub(/\.\w+$/, "")}-#{config.report_suffix}#{::File.extname(path)}"
    end

    def notify_spring_detected
      return if instance_variable_defined?(:@spring_notified)
      log :info, "Spring detected"
      @spring_notified = true
    end

    def notify_spring_activate(env_var)
      log :info, "Activating #{env_var} with `Spring.after_fork`"
    end
  end

  # TestProf configuration
  class Configuration
    attr_accessor :output, # IO to write logs
      :color, # Whether to colorize output or not
      :output_dir, # Directory to store artifacts
      :timestamps, # Whether to use timestamped names for artifacts,
      :report_suffix # Custom suffix for reports/artifacts

    def initialize
      @output = $stdout
      @color = true
      @output_dir = "tmp/test_prof"
      @timestamps = false
      @report_suffix = ENV["TEST_PROF_REPORT"]
    end

    def color?
      color == true && output.is_a?(IO) && output.tty?
    end

    def timestamps?
      timestamps == true
    end

    def logger
      @logger ||= Logger.new(output, formatter: Logging::Formatter.new)
    end
  end
end

require "test_prof/ruby_prof"
require "test_prof/stack_prof"
require "test_prof/event_prof"
require "test_prof/factory_doctor"
require "test_prof/factory_prof"
require "test_prof/rspec_stamp"
require "test_prof/tag_prof"
require "test_prof/rspec_dissect" if TestProf.rspec?
require "test_prof/factory_all_stub"
