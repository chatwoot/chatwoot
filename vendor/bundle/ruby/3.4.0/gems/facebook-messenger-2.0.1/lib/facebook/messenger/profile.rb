require 'httparty'

module Facebook
  module Messenger
    #
    # This module provide functionality to manage the messenger profile.
    # @see https://developers.facebook.com/docs/messenger-platform/messenger-profile
    #
    module Profile
      include HTTParty

      # Define base_uri for HTTParty.
      base_uri 'https://graph.facebook.com/v3.2/me'

      format :json

      module_function

      #
      # Set the messenger profile.
      #
      # @raise [Facebook::Messenger::Profile::Error] if there is any error
      #   in response.
      #
      # @param [Hash] settings Hash defining the profile settings.
      # @param [String] access_token  Access token of facebook page.
      #
      # @return [Boolean] If profile is successfully set, return true.
      #
      def set(settings, access_token:)
        response = post '/messenger_profile', body: settings.to_json, query: {
          access_token: access_token
        }

        raise_errors(response)

        true
      end

      #
      # Unset the messenger profile.
      #
      # @raise [Facebook::Messenger::Profile::Error] if there is any error
      #   in response.
      #
      # @param [Hash] settings Hash defining the profile settings.
      # @param [String] access_token  Access token of facebook page.
      #
      # @return [Boolean] If profile is successfully removed, return true.
      #
      def unset(settings, access_token:)
        response = delete '/messenger_profile', body: settings.to_json, query: {
          access_token: access_token
        }

        raise_errors(response)

        true
      end

      #
      # Function raise error if response has error key.
      #
      # @raise [Facebook::Messenger::Profile::Error] if error is present
      #   in response.
      #
      # @param [Hash] response Response hash from facebook.
      #
      def raise_errors(response)
        raise Error, response['error'] if response.key? 'error'
      end

      #
      # Default HTTParty options.
      #
      # @return [Hash] Default HTTParty options.
      #
      def default_options
        super.merge(
          headers: {
            'Content-Type' => 'application/json'
          }
        )
      end

      #
      # Class Error provides errors related to profile subscriptions.
      #
      class Error < Facebook::Messenger::FacebookError; end
    end
  end
end
