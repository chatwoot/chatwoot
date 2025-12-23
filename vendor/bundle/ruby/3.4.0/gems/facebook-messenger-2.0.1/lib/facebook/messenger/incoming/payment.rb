module Facebook
  module Messenger
    module Incoming
      # The Payment class represents a successful purchase using the Buy Button
      #
      # https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/payment
      class Payment
        include Facebook::Messenger::Incoming::Common

        # The payment portion of the payload.
        class Payment
          def initialize(payment)
            @payment = payment
          end

          # Return String containing developer defined payload.
          def payload
            @payment['payload']
          end

          # Return hash containing the requested information from user when they
          #   click buy button.
          def user_info
            @payment['requested_user_info']
          end

          # Return hash containing the payment credential information.
          def payment_credential
            @payment['payment_credential']
          end

          # Return hash containing the information about amount of purchase.
          def amount
            @payment['amount']
          end

          # Return string containing option_id of selected shipping option.
          def shipping_option_id
            @payment['shipping_option_id']
          end
        end

        def payment
          @payment ||= Payment.new(@messaging['payment'])
        end
      end
    end
  end
end
