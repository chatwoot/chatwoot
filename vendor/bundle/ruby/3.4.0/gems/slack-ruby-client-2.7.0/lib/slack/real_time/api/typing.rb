# frozen_string_literal: true
module Slack
  module RealTime
    module Api
      module Typing
        #
        # Send a typing indicator to indicate that the user is currently writing a message.
        #
        # @option options [channel] :channel
        #   Channel to send message to. Can be a public channel, private group or IM channel.
        #   Can be an encoded ID, or a name.
        def typing(options = {})
          raise ArgumentError, 'Required arguments :channel missing' if options[:channel].nil?

          send_json({ type: 'typing', id: next_id }.merge(options))
        end
      end
    end
  end
end
