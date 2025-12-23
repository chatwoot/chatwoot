module Twilio
  module REST
    class FrontlineApi < FrontlineApiBase
      ##
      # @param [String] sid The unique string that we created to identify the User
      #   resource.
      # @return [Twilio::REST::Frontline_api::V1::UserInstance] if sid was passed.
      # @return [Twilio::REST::Frontline_api::V1::UserList]
      def users(sid=:unset)
        warn "users is deprecated. Use v1.users instead."
        self.v1.users(sid)
      end
    end
  end
end