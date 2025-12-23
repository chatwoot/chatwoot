# frozen_string_literal: true

module Lograge
  module LogSubscribers
    class ActionCable < Base
      %i[perform_action subscribe unsubscribe connect disconnect].each do |method_name|
        define_method(method_name) do |event|
          process_main_event(event)
        end
      end

      private

      def initial_data(payload)
        {
          method: nil,
          path: nil,
          format: nil,
          params: payload[:data],
          controller: payload[:channel_class] || payload[:connection_class],
          action: payload[:action]
        }
      end

      def default_status
        200
      end

      def extract_runtimes(event, _payload)
        { duration: event.duration.to_f.round(2) }
      end
    end
  end
end
