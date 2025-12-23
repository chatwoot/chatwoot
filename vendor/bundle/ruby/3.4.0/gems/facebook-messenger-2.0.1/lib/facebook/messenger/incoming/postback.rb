module Facebook
  module Messenger
    module Incoming
      # The Postback class represents an incoming Facebook Messenger
      #   postback events.
      # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_postbacks
      class Postback
        include Facebook::Messenger::Incoming::Common

        # Return String of developer defined payload.
        def payload
          @messaging['postback']['payload']
        end

        # Return hash containing the referral information of user.
        def referral
          return if @messaging['postback']['referral'].nil?

          @referral ||= Referral::Referral.new(
            @messaging['postback']['referral']
          )
        end
      end
    end
  end
end
