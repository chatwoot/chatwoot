module Twilio
  module REST
    class Accounts < AccountsBase
      ##
      # @return [Twilio::REST::Accounts::V1::AuthTokenPromotionInstance]
      def auth_token_promotion
        warn "auth_token_promotion is deprecated. Use v1.auth_token_promotion instead."
        self.v1.auth_token_promotion()
      end

      ##
      # @return [Twilio::REST::Accounts::V1::CredentialInstance]
      def credentials
        warn "credentials is deprecated. Use v1.credentials instead."
        self.v1.credentials()
      end

      ##
      # @return [Twilio::REST::Accounts::V1::SecondaryAuthTokenInstance]
      def secondary_auth_token
        warn "secondary_auth_token is deprecated. Use v1.secondary_auth_token instead."
        self.v1.secondary_auth_token()
      end
    end
  end
end