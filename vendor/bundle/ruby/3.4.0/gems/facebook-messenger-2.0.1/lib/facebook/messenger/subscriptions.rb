require 'httparty'

module Facebook
  module Messenger
    #
    # Module Subscriptions handles subscribing and unsubscribing Applications
    #   to Pages.
    #
    module Subscriptions
      include HTTParty

      base_uri 'https://graph.facebook.com/v3.2/me'

      format :json

      module_function

      #
      # Function subscribe the facebook app to page.
      # @see https://developers.facebook.com/docs/graph-api/reference/page/subscribed_apps
      #
      # @raise [Facebook::Messenger::Subscriptions::Error] if there is any error
      #   in the response of subscribed_apps request.
      #
      # @param [String] access_token Access token of page to which bot has
      #   to subscribe.
      #
      # @return [Boolean] TRUE
      #
      def subscribe(access_token:, subscribed_fields: [])
        response = post '/subscribed_apps',
                        headers: { 'Content-Type' => 'application/json' },
                        body: {
                          access_token: access_token,
                          subscribed_fields: subscribed_fields
                        }.to_json

        raise_errors(response)

        true
      end

      #
      # Function unsubscribe the app from facebook page.
      # @see https://developers.facebook.com/docs/graph-api/reference/page/subscribed_apps
      #
      # @raise [Facebook::Messenger::Subscriptions::Error] if there is any error
      #   in the response of subscribed_apps request.
      #
      # @param [String] access_token Access token of page from which app has
      #   to unsubscribe.
      #
      # @return [Boolean] TRUE
      #
      def unsubscribe(access_token:)
        response = delete '/subscribed_apps', query: {
          access_token: access_token
        }

        raise_errors(response)

        true
      end

      #
      # If there is any error in response, raise error.
      #
      # @raise [Facebook::Messenger::Subscriptions::Error] If there is error
      #   in response.
      #
      # @param [Hash] response Response from facebook.
      #
      # @return Raise the error.
      #
      def raise_errors(response)
        raise Error, response['error'] if response.key? 'error'
      end

      #
      # Class Error provides errors related to subscriptions.
      #
      class Error < Facebook::Messenger::FacebookError; end
    end
  end
end
