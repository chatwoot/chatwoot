module Twilio
  module REST
    class Chat < ChatBase
      ##
      # @param [String] sid The unique string that we created to identify the Credential
      #   resource.
      # @return [Twilio::REST::Chat::V2::CredentialInstance] if sid was passed.
      # @return [Twilio::REST::Chat::V2::CredentialList]
      def credentials(sid=:unset)
        warn "credentials is deprecated. Use v2.credentials instead."
        self.v2.credentials(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Service
      #   resource.
      # @return [Twilio::REST::Chat::V2::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Chat::V2::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v2.services instead."
        self.v2.services(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Channel
      #   resource.
      # @return [Twilio::REST::Chat::V3::ChannelInstance] if sid was passed.
      # @return [Twilio::REST::Chat::V3::ChannelList]
      def channels(service_sid=:unset, sid=:unset)
        warn "channels is deprecated. Use v3.channels instead."
        self.v3.channels(service_sid, sid)
      end
    end
  end
end