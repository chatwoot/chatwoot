# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  class Control
    # Contains methods that relate to adding and executing files that
    # contain instrumentation for the Ruby Agent
    module Instrumentation
      # Adds a list of files in Dir.glob format
      # (e.g. '/app/foo/**/*_instrumentation.rb')
      # This requires the files within a rescue block, so that any
      # errors within instrumentation files do not affect the overall
      # agent or application in which it runs.
      def load_instrumentation_files(pattern)
        Dir.glob(pattern) do |file|
          begin
            require file.to_s
          rescue => e
            ::NewRelic::Agent.logger.warn("Error loading instrumentation file '#{file}':", e)
          end
        end
      end

      def install_shim
        # implemented only in subclasses
      end

      # Add instrumentation.  Don't call this directly.  Use NewRelic::Agent#add_instrumentation.
      # This will load the file synchronously if we've already loaded the default
      # instrumentation, otherwise instrumentation files specified
      # here will be deferred until all instrumentation is run
      #
      # This happens after the agent has loaded and all dependencies
      # are ready to be instrumented
      def add_instrumentation(pattern)
        if @instrumented
          load_instrumentation_files(pattern)
        else
          @instrumentation_files << pattern
        end
      end

      # Signals the agent that it's time to actually load the
      # instrumentation files. May be overridden by subclasses
      def install_instrumentation
        _install_instrumentation
      end

      private

      def _install_instrumentation
        return if @instrumented

        @instrumented = true

        # Instrumentation for the key code points inside rails for monitoring by NewRelic.
        # note this file is loaded only if the newrelic agent is enabled (through config/newrelic.yml)
        instrumentation_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'agent', 'instrumentation'))
        @instrumentation_files <<
          File.join(instrumentation_path, '*.rb') <<
          File.join(instrumentation_path, app.to_s, '*.rb')
        @instrumentation_files.each { |pattern| load_instrumentation_files(pattern) }
        DependencyDetection.detect!
        rails_32_deprecation
        ::NewRelic::Agent.logger.info('Finished instrumentation')
      end
    end

    def rails_32_deprecation
      return unless defined?(Rails::VERSION) && Gem::Version.new(Rails::VERSION::STRING) <= Gem::Version.new('3.2')

      deprecation_msg = 'The Ruby Agent is dropping support for Rails 3.2 ' \
        'in a future major release. Please upgrade your Rails version to continue receiving support. ' \

      Agent.logger.log_once(
        :warn,
        :deprecated_rails_version,
        deprecation_msg
      )
    end

    include Instrumentation
  end
end
