# frozen_string_literal: true

class UniformNotifier
  class HoneybadgerNotifier < Base
    class << self
      def active?
        !!UniformNotifier.honeybadger
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        opt = {}
        opt = UniformNotifier.honeybadger if UniformNotifier.honeybadger.is_a?(Hash)

        exception = Exception.new(message)
        honeybadger_class = opt[:honeybadger_class] || Honeybadger
        honeybadger_class.notify(exception, opt)
      end
    end
  end
end
