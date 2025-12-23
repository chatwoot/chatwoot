module Facebook
  module Messenger
    module Incoming
      #
      # The Optin class represents an incoming Facebook Messenger optin,
      # which occurs when a user engages by using the Send-to-Messenger Plugin.
      #
      # @see https://developers.facebook.com/docs/messenger-platform/plugin-reference
      #
      class Optin
        include Facebook::Messenger::Incoming::Common

        #
        # Function returns 'data-ref' attribute that was defined
        #   with the entry point.
        #
        # @return [String] data-ref attribute.
        #
        def ref
          @messaging['optin']['ref']
        end

        #
        # Function returns 'user_ref' attribute defined in checkbox plugin.
        #
        # @return [String] user-ref attribute.
        #
        def user_ref
          @messaging['optin']['user_ref']
        end
      end
    end
  end
end
