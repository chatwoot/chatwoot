module Twilio
  module REST
    class Notify < NotifyBase
      ##
      # @param [String] sid The unique string that we created to identify the Credential
      #   resource.
      # @return [Twilio::REST::Notify::V1::CredentialInstance] if sid was passed.
      # @return [Twilio::REST::Notify::V1::CredentialList]
      def credentials(sid=:unset)
        warn "credentials is deprecated. Use v1.credentials instead."
        self.v1.credentials(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Service
      #   resource.
      # @return [Twilio::REST::Notify::V1::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Notify::V1::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v1.services instead."
        self.v1.services(sid)
      end
    end
  end
end