# frozen_string_literal: true

require_relative "../../core/utils/only_once"
require_relative "../../core/utils/at_fork_monkey_patch"

module Datadog
  module Profiling
    module Tasks
      # Takes care of restarting the profiler when the process forks
      class Setup
        ACTIVATE_EXTENSIONS_ONLY_ONCE = Core::Utils::OnlyOnce.new

        def run
          ACTIVATE_EXTENSIONS_ONLY_ONCE.run do
            Datadog::Core::Utils::AtForkMonkeyPatch.apply!
            setup_at_fork_hooks
          rescue StandardError, ScriptError => e
            Datadog.logger.warn do
              "Profiler extensions unavailable. Cause: #{e.class.name} #{e.message} " \
              "Location: #{Array(e.backtrace).first}"
            end
            Datadog::Core::Telemetry::Logger.report(e, description: "Profiler extensions unavailable")
          end
        end

        private

        def setup_at_fork_hooks
          Datadog::Core::Utils::AtForkMonkeyPatch.at_fork(:child) do
            # Restart profiler, if enabled
            Profiling.start_if_enabled
          rescue => e
            Datadog.logger.warn do
              "Error during post-fork hooks. Cause: #{e.class.name} #{e.message} " \
              "Location: #{Array(e.backtrace).first}"
            end
            Datadog::Core::Telemetry::Logger.report(e, description: "Error during post-fork hooks")
          end
        end
      end
    end
  end
end
