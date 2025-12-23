module Facebook
  module Messenger
    module Incoming
      # The Read class represents the user reading a delivered message.
      # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/message-reads
      class Read
        include Facebook::Messenger::Incoming::Common

        # Return time object when message is read by user.
        def at
          Time.at(@messaging['read']['watermark'] / 1000)
        end

        # Return Integer defining the sequence number of message.
        def seq
          @messaging['read']['seq']
        end
      end
    end
  end
end
