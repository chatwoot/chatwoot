# frozen_string_literal: true

require_relative '../utils/time'
require_relative '../utils/only_once'
require_relative '../telemetry/logger'
require_relative '../configuration/ext'

require_relative 'ext'
require_relative 'options'
require_relative 'helpers'
require_relative 'logging'
require_relative 'metric'

module Datadog
  module Core
    module Metrics
      # Acts as client for sending metrics (via Statsd)
      # Wraps a Statsd client with default tags and additional configuration.
      class Client
        include Options
        extend Options
        extend Helpers

        attr_reader :statsd, :logger, :telemetry

        def initialize(telemetry:, logger: Datadog.logger, statsd: nil, enabled: true, **_)
          @telemetry = telemetry
          @logger = logger
          @statsd =
            if supported?
              statsd || default_statsd_client
            else
              ignored_statsd_warning if statsd
              nil
            end
          @enabled = enabled
        end

        def supported?
          version = dogstatsd_version

          !version.nil? && version >= Gem::Version.new('3.3.0') &&
            # dogstatsd-ruby >= 5.0 & < 5.2.0 has known issues with process forks
            # and do not support the single thread mode we use to avoid this problem.
            !(version >= Gem::Version.new('5.0') && version < Gem::Version.new('5.3'))
        end

        def enabled?
          @enabled
        end

        def enabled=(enabled)
          @enabled = (enabled == true)
        end

        def default_hostname
          ENV.fetch(Configuration::Ext::Agent::ENV_DEFAULT_HOST, Ext::DEFAULT_HOST)
        end

        def default_port
          ENV.fetch(Configuration::Ext::Metrics::ENV_DEFAULT_PORT, Ext::DEFAULT_PORT).to_i
        end

        def default_statsd_client
          require 'datadog/statsd'

          # Create a StatsD client that points to the agent.
          #
          # We use `single_thread: true`, as dogstatsd-ruby >= 5.0 creates a background thread
          # by default, but does not handle forks correctly, causing resource leaks.
          #
          # Using dogstatsd-ruby >= 5.0 is still valuable, as it supports
          # transparent batch metric submission, which reduces submission
          # overhead.
          #
          # Versions < 5.0 are always single-threaded, but do not have the kwarg option.
          options = if dogstatsd_version >= Gem::Version.new('5.2')
            {single_thread: true}
          else
            {}
          end

          Datadog::Statsd.new(default_hostname, default_port, **options)
        end

        def configure(options = {})
          @statsd = options[:statsd] if options.key?(:statsd)
          self.enabled = options[:enabled] if options.key?(:enabled)
        end

        def send_stats?
          enabled? && !statsd.nil?
        end

        def count(stat, value = nil, options = nil, &block)
          return unless send_stats? && statsd.respond_to?(:count)

          value, options = yield if block
          raise ArgumentError if value.nil?

          statsd.count(stat, value, metric_options(options))
        rescue => e
          logger.error(
            "Failed to send count stat. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
          )
          telemetry.report(e, description: 'Failed to send count stat')
        end

        def distribution(stat, value = nil, options = nil, &block)
          return unless send_stats? && statsd.respond_to?(:distribution)

          value, options = yield if block
          raise ArgumentError if value.nil?

          statsd.distribution(stat, value, metric_options(options))
        rescue => e
          logger.error(
            "Failed to send distribution stat. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
          )
          telemetry.report(e, description: 'Failed to send distribution stat')
        end

        def increment(stat, options = nil)
          return unless send_stats? && statsd.respond_to?(:increment)

          options = yield if block_given?

          statsd.increment(stat, metric_options(options))
        rescue => e
          logger.error(
            "Failed to send increment stat. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
          )
          telemetry.report(e, description: 'Failed to send increment stat')
        end

        def gauge(stat, value = nil, options = nil, &block)
          return unless send_stats? && statsd.respond_to?(:gauge)

          value, options = yield if block
          raise ArgumentError if value.nil?

          statsd.gauge(stat, value, metric_options(options))
        rescue => e
          logger.error(
            "Failed to send gauge stat. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
          )
          telemetry.report(e, description: 'Failed to send gauge stat')
        end

        def time(stat, options = nil)
          return yield unless send_stats?

          # Calculate time, send it as a distribution.
          start = Utils::Time.get_time
          yield
        ensure
          begin
            if send_stats? && !start.nil?
              finished = Utils::Time.get_time
              distribution(stat, ((finished - start) * 1000), options)
            end
          rescue => e
            # TODO: Likely to be redundant, since `distribution` handles its own errors.
            logger.error(
              "Failed to send time stat. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
            )
            telemetry.report(e, description: 'Failed to send time stat')
          end
        end

        def send_metrics(metrics)
          metrics.each { |m| send(m.type, *[m.name, m.value, m.options].compact) }
        end

        def close
          @statsd.close if @statsd&.respond_to?(:close)
        end

        private

        def dogstatsd_version
          return @dogstatsd_version if instance_variable_defined?(:@dogstatsd_version)

          @dogstatsd_version = (
            defined?(Datadog::Statsd::VERSION) &&
              Datadog::Statsd::VERSION &&
              Gem::Version.new(Datadog::Statsd::VERSION)
          ) ||
            Gem.loaded_specs['dogstatsd-ruby']&.version
        end

        IGNORED_STATSD_ONLY_ONCE = Utils::OnlyOnce.new
        private_constant :IGNORED_STATSD_ONLY_ONCE

        def ignored_statsd_warning
          IGNORED_STATSD_ONLY_ONCE.run do
            logger.warn(
              'Ignoring user-supplied statsd instance as currently-installed version of dogstastd-ruby is incompatible. ' \
              "To fix this, ensure that you have `gem 'dogstatsd-ruby', '~> 5.3'` on your Gemfile or gems.rb file."
            )
          end
        end
      end
    end
  end
end
