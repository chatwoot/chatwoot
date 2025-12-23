# frozen_string_literal: true

module Lograge
  module ActionCable
    module ChannelInstrumentation
      def subscribe_to_channel
        ActiveSupport::Notifications.instrument('subscribe.action_cable', notification_payload('subscribe')) { super }
      end

      def unsubscribe_from_channel
        ActiveSupport::Notifications.instrument('unsubscribe.action_cable', notification_payload('unsubscribe')) do
          super
        end
      end

      private

      def notification_payload(method_name)
        { channel_class: self.class.name, action: method_name }
      end
    end
  end
end

ActionCable::Channel::Base.prepend(Lograge::ActionCable::ChannelInstrumentation)
