module Facebook
  module Messenger
    module Incoming
      #
      # The AccountLinking class represents an incoming Facebook Messenger
      # Account Linking webhook, when the Linked Account
      # or Unlink Account call-to-action have been tapped
      #
      # https://developers.facebook.com/docs/messenger-platform/webhook-reference/account-linking
      #
      class AccountLinking
        include Facebook::Messenger::Incoming::Common

        # Return String defining whether account in linked or not.
        #
        # @return [String] linked/unlinked.
        def status
          @messaging['account_linking']['status']
        end

        # The authorization code allows to match business user entity to PSID.
        def authorization_code
          @messaging['account_linking']['authorization_code']
        end
      end
    end
  end
end
