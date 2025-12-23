# frozen_string_literal: true
module Slack
  module RealTime
    module Api
      module Ping
        #
        # Clients should try to quickly detect disconnections, even in idle periods, so that users
        # can easily tell the
        # difference between being disconnected and everyone being quiet. Not all web browsers
        # support the WebSocket
        # ping spec, so the RTM protocol also supports ping/pong messages.
        #
        def ping(options = {})
          send_json({ type: 'ping', id: next_id }.merge(options))
        end
      end
    end
  end
end
