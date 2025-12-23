# frozen_string_literal: true

module Datadog
  module Kit
    # This helper is used to enable core dumps for the current Ruby app. This is useful when debugging native-level
    # crashes.
    #
    # It can be enabled simply by adding `require 'datadog/kit/enable_core_dumps'` to start of the app.
    module EnableCoreDumps
      def self.call
        current_size, maximum_size = Process.getrlimit(:CORE)
        core_pattern =
          begin
            File.read('/proc/sys/kernel/core_pattern').strip
          rescue
            '(Could not open /proc/sys/kernel/core_pattern)'
          end

        enabled_status = "Maximum size: #{maximum_size} Output pattern: '#{core_pattern}'"

        if maximum_size <= 0
          Kernel.warn("[datadog] Could not enable core dumps on crash, maximum size is #{maximum_size} (disabled).")
          return
        elsif maximum_size == current_size
          Kernel.warn("[datadog] Core dumps already enabled, nothing to do. #{enabled_status}")
          return
        end

        begin
          Process.setrlimit(:CORE, maximum_size)
        rescue => e
          Kernel.warn(
            "[datadog] Failed to enable core dumps. Cause: #{e.class.name} #{e.message} " \
            "Location: #{Array(e.backtrace).first}"
          )
          return
        end

        if current_size == 0
          Kernel.warn("[datadog] Enabled core dumps. #{enabled_status}")
        else
          Kernel.warn("[datadog] Raised core dump limit. Old size: #{current_size} #{enabled_status}")
        end
      end
    end
  end
end

Datadog::Kit::EnableCoreDumps.call
