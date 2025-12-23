# frozen_string_literal: true

class UniformNotifier
  class RailsLogger < Base
    class << self
      def active?
        UniformNotifier.rails_logger
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        Rails.logger.warn message
      end
    end
  end
end
