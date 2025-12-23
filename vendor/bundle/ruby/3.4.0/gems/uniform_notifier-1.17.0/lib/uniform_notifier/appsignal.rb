# frozen_string_literal: true

class UniformNotifier
  class AppsignalNotifier < Base
    class << self
      def active?
        !!UniformNotifier.appsignal
      end

      protected

      def _out_of_channel_notify(data)
        opt = UniformNotifier.appsignal.is_a?(Hash) ? UniformNotifier.appsignal : {}

        exception = Exception.new("#{data[:title]}\n#{data[:body]}")
        exception.set_backtrace(data[:backtrace]) if data[:backtrace]

        tags = opt.fetch(:tags, {}).merge(data.fetch(:tags, {}))
        namespace = data[:namespace] || opt[:namespace]

        Appsignal.send_error(exception) do |transaction|
          transaction.set_tags(tags)
          transaction.set_namespace(namespace)
        end
      end
    end
  end
end
