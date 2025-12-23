# frozen_string_literal: true

class UniformNotifier
  class BugsnagNotifier < Base
    class << self
      def active?
        !!UniformNotifier.bugsnag
      end

      protected

      def _out_of_channel_notify(data)
        exception = Exception.new(data[:title])
        exception.set_backtrace(data[:backtrace]) if data[:backtrace]

        return nil if data.empty?

        Bugsnag.notify(exception) do |report|
          report.severity = "warning"
          report.add_tab(:bullet, data)
          report.grouping_hash = data[:body] || data[:title]

          if UniformNotifier.bugsnag.is_a?(Proc)
            UniformNotifier.bugsnag.call(report)
          end
        end
      end
    end
  end
end
