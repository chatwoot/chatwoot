# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module ActiveSupportBroadcastLogger::Chain
    def self.instrument!
      ::ActiveSupportBroadcastLogger.class_eval do
        include NewRelic::Agent::Instrumentation::ActiveSupportBroadcastLogger

        alias_method(:add_without_new_relic, :add)

        def add(*args, &task)
          record_one_broadcast_with_new_relic(*args) do
            add_without_new_relic(*args, &traced_task)
          end
        end

        alias_method(:debug_without_new_relic, :debug)

        def debug(*args, &task)
          record_one_broadcast_with_new_relic(*args) do
            debug_without_new_relic(*args, &traced_task)
          end
        end

        alias_method(:info_without_new_relic, :info)

        def info(*args, &task)
          record_one_broadcast_with_new_relic(*args) do
            info_without_new_relic(*args, &traced_task)
          end
        end

        alias_method(:warn_without_new_relic, :warn)

        def warn(*args, &task)
          record_one_broadcast_with_new_relic(*args) do
            warn_without_new_relic(*args, &traced_task)
          end
        end

        alias_method(:error_without_new_relic, :error)

        def error(*args, &task)
          record_one_broadcast_with_new_relic(*args) do
            error_without_new_relic(*args, &traced_task)
          end
        end

        alias_method(:fatal_without_new_relic, :fatal)

        def fatal(*args, &task)
          record_one_broadcast_with_new_relic(*args) do
            fatal_without_new_relic(*args, &traced_task)
          end
        end
      end

      alias_method(:unknown_without_new_relic, :unknown)

      def unknown(*args, &task)
        record_one_broadcast_with_new_relic(*args) do
          unknown_without_new_relic(*args, &traced_task)
        end
      end
    end
  end
end
