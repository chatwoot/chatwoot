module Twilio
  module REST
    class Serverless < ServerlessBase
      ##
      # @param [String] sid The unique string that we created to identify the Service
      #   resource.
      # @return [Twilio::REST::Serverless::V1::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Serverless::V1::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v1.services instead."
        self.v1.services(sid)
      end
    end
  end
end