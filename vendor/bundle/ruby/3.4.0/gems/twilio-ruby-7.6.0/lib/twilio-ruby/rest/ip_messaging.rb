module Twilio
  module REST
    class IpMessaging < IpMessagingBase
      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Ip_messaging::V2::CredentialInstance] if sid was passed.
      # @return [Twilio::REST::Ip_messaging::V2::CredentialList]
      def credentials(sid=:unset)
        warn "credentials is deprecated. Use v2.credentials instead."
        self.v2.credentials(sid)
      end

      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Ip_messaging::V2::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Ip_messaging::V2::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v2.services instead."
        self.v2.services(sid)
      end
    end
  end
end