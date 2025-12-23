module Facebook
  module Messenger
    module Incoming
      # The Message echo class represents an incoming Facebook Messenger message
      # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/message-reactions
      class MessageReaction
        include Facebook::Messenger::Incoming::Common

        def action
          @messaging['reaction']['action']
        end

        def emoji
          @messaging['reaction']['emoji']
        end

        def reaction
          @messaging['reaction']['reaction']
        end
      end
    end
  end
end
