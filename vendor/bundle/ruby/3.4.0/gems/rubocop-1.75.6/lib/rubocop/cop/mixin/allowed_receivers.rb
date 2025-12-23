# frozen_string_literal: true

module RuboCop
  module Cop
    # This module encapsulates the ability to allow certain receivers in a cop.
    module AllowedReceivers
      def allowed_receiver?(receiver)
        receiver_name = receiver_name(receiver)

        allowed_receivers.include?(receiver_name)
      end

      def receiver_name(receiver)
        if receiver.receiver && !receiver.receiver.const_type?
          return receiver_name(receiver.receiver)
        end

        if receiver.send_type?
          if receiver.receiver
            "#{receiver_name(receiver.receiver)}.#{receiver.method_name}"
          else
            receiver.method_name.to_s
          end
        else
          receiver.source
        end
      end

      def allowed_receivers
        cop_config.fetch('AllowedReceivers', [])
      end
    end
  end
end
