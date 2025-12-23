module Facebook
  module Messenger
    module Incoming
      # Referral class represents an incoming Facebook Messenger referral event.
      #
      # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_referrals
      class Referral
        include Facebook::Messenger::Incoming::Common

        # The referral portion of the payload.
        class Referral
          def initialize(referral)
            @referral = referral
          end

          # Return String of ref data set in referrer.
          def ref
            @referral['ref']
          end

          # Return String of referral source.
          def source
            @referral['source']
          end

          # Return String of referral type.
          def type
            @referral['type']
          end

          # Return String of ad id.
          def ad_id
            @referral['ad_id'] if @referral.key?('ad_id')
          end
        end

        def referral
          @referral ||= Referral.new(@messaging['referral'])
        end

        def ref
          referral.ref
        end
      end
    end
  end
end
