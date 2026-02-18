# WhatsApp Calling via YCloud API.
# Enables voice calls within WhatsApp conversations.
# https://docs.ycloud.com/reference/whatsapp-calling
module Whatsapp::Ycloud
  class CallService
    pattr_initialize [:whatsapp_channel!]

    # Initiate a business-originated call.
    # @param params [Hash]:
    #   - from [String] Business phone number
    #   - to [String] Customer phone number
    #   - sdpOffer [String] SDP offer for WebRTC
    def connect(params)
      client.post('/whatsapp/calls/connect', params.merge(from: whatsapp_channel.phone_number))
    end

    # Pre-accept an incoming call (shows ringing state to caller).
    # @param params [Hash]:
    #   - callId [String] Call ID from webhook
    def pre_accept(params)
      client.post('/whatsapp/calls/pre-accept', params)
    end

    # Accept an incoming call.
    # @param params [Hash]:
    #   - callId [String] Call ID
    #   - sdpAnswer [String] SDP answer for WebRTC
    def accept(params)
      client.post('/whatsapp/calls/accept', params)
    end

    # Terminate an active call.
    # @param params [Hash]:
    #   - callId [String] Call ID
    def terminate(params)
      client.post('/whatsapp/calls/terminate', params)
    end

    # Reject an incoming call.
    # @param params [Hash]:
    #   - callId [String] Call ID
    def reject(params)
      client.post('/whatsapp/calls/reject', params)
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
