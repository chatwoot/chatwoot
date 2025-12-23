# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class Harvester
      attr_accessor :starting_pid

      # Inject target for after_fork call to avoid spawning thread in tests
      def initialize(events, after_forker = NewRelic::Agent)
        # We intentionally don't set our pid as started at this point.
        # Startup routines must call mark_started when they consider us set!
        @starting_pid = nil
        @after_forker = after_forker

        events&.subscribe(:start_transaction, &method(:on_transaction))
      end

      def on_transaction(*_)
        return unless restart_in_children_enabled? &&
          needs_restart? &&
          harvest_thread_enabled?

        restart_harvest_thread
      end

      def mark_started(pid = Process.pid)
        @starting_pid = pid
      end

      def needs_restart?(pid = Process.pid)
        @starting_pid != pid
      end

      def restart_in_children_enabled?
        NewRelic::Agent.config[:restart_thread_in_children]
      end

      def harvest_thread_enabled?
        !NewRelic::Agent.config[:disable_harvest_thread]
      end

      def restart_harvest_thread
        @after_forker.after_fork(:force_reconnect => true)
      end
    end
  end
end
