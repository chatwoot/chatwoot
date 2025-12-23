module Koala
  module Facebook
    class RealtimeUpdates
      # Manage realtime callbacks for changes to users' information.
      # See http://developers.facebook.com/docs/reference/api/realtime.
      #
      # @note: to subscribe to real-time updates, you must have an application access token
      #        or provide the app secret when initializing your RealtimeUpdates object.

      attr_reader :app_id, :app_access_token, :secret

      # Create a new RealtimeUpdates instance.
      # If you don't have your app's access token, provide the app's secret and
      # Koala will make a request to Facebook for the appropriate token.
      #
      # @param options initialization options.
      # @option options :app_id the application's ID.
      # @option options :app_access_token an application access token, if known.
      # @option options :secret the application's secret.
      #
      # @raise ArgumentError if the application ID and one of the app access token or the secret are not provided.
      def initialize(options = {})
        @app_id = options[:app_id] || Koala.config.app_id
        @app_access_token = options[:app_access_token] || Koala.config.app_access_token
        @secret = options[:secret] || Koala.config.app_secret
        unless @app_id && (@app_access_token || @secret) # make sure we have what we need
          raise ArgumentError, "Initialize must receive a hash with :app_id and either :app_access_token or :secret! (received #{options.inspect})"
        end
      end

      # The app access token, either provided on initialization or fetched from Facebook using the
      # app_id and secret.
      def app_access_token
        # If a token isn't provided but we need it, fetch it
        @app_access_token ||= Koala::Facebook::OAuth.new(@app_id, @secret).get_app_access_token
      end

      # The application API interface used to communicate with Facebook.
      # @return [Koala::Facebook::API]
      def api
        # Only instantiate the API if needed. validate_update doesn't require it, so we shouldn't
        # make an unnecessary request to get the app_access_token.
        @api ||= API.new(app_access_token)
      end

      # Subscribe to realtime updates for certain fields on a given object (user, page, etc.).
      # See {http://developers.facebook.com/docs/reference/api/realtime the realtime updates documentation}
      # for more information on what objects and fields you can register for.
      #
      # @note Your callback_url must be set up to handle the verification request or the subscription will not be set up.
      #
      # @param object a Facebook ID (name or number)
      # @param fields the fields you want your app to be updated about
      # @param callback_url the URL Facebook should ping when an update is available
      # @param verify_token a token included in the verification request, allowing you to ensure the call is genuine
      #                     (see the docs for more information)
      # @param options (see Koala::HTTPService.make_request)
      #
      # @raise A subclass of Koala::Facebook::APIError if the subscription request failed.
      def subscribe(object, fields, callback_url, verify_token, options = {})
        args = {
          :object => object,
          :fields => fields,
          :callback_url => callback_url,
        }.merge(verify_token ? {:verify_token => verify_token} : {})
        # a subscription is a success if Facebook returns a 200 (after hitting your server for verification)
        api.graph_call(subscription_path, args, 'post', options)
      end

      # Unsubscribe from updates for a particular object or from updates.
      #
      # @param object the object whose subscriptions to delete.
      #               If no object is provided, all subscriptions will be removed.
      # @param options (see Koala::HTTPService.make_request)
      #
      # @raise A subclass of Koala::Facebook::APIError if the subscription request failed.
      def unsubscribe(object = nil, options = {})
        api.graph_call(subscription_path, object ? {:object => object} : {}, "delete", options)
      end

      # List all active subscriptions for this application.
      #
      # @param options (see Koala::HTTPService.make_request)
      #
      # @return [Array] a list of active subscriptions
      def list_subscriptions(options = {})
        api.graph_call(subscription_path, {}, "get", options)
      end

      # As a security measure (to prevent DDoS attacks), Facebook sends a verification request to your server
      # after you request a subscription.
      # This method parses the challenge params and makes sure the call is legitimate.
      #
      # @param params the request parameters sent by Facebook.  (You can pass in a Rails params hash.)
      # @param verify_token the verify token sent in the {#subscribe subscription request}, if you provided one
      #
      # @yield verify_token if you need to compute the verification token
      #                     (for instance, if your callback URL includes a record ID, which you look up
      #                     and use to calculate a hash), you can pass meet_challenge a block, which
      #                     will receive the verify_token received back from Facebook.
      #
      # @return the challenge string to be sent back to Facebook, or false if the request is invalid.
      def self.meet_challenge(params, verify_token = nil, &verification_block)
        if params["hub.mode"] == "subscribe" &&
            # you can make sure this is legitimate through two ways
            # if your store the token across the calls, you can pass in the token value
            # and we'll make sure it matches
            ((verify_token && params["hub.verify_token"] == verify_token) ||
            # alternately, if you sent a specially-constructed value (such as a hash of various secret values)
            # you can pass in a block, which we'll call with the verify_token sent by Facebook
            # if it's legit, return anything that evaluates to true; otherwise, return nil or false
            (verification_block && yield(params["hub.verify_token"])))
          params["hub.challenge"]
        else
          false
        end
      end

      # Public: As a security measure, all updates from facebook are signed using
      # X-Hub-Signature: sha1=XXXX where XXX is the sha1 of the json payload
      # using your application secret as the key.
      #
      # Example:
      #   # in Rails controller
      #   # @oauth being a previously defined Koala::Facebook::OAuth instance
      #   def receive_update
      #     if @oauth.validate_update(request.body, headers)
      #       ...
      #     end
      #   end
      def validate_update(body, headers)
        unless @secret
          raise AppSecretNotDefinedError, "You must init RealtimeUpdates with your app secret in order to validate updates"
        end

        request_signature = headers['X-Hub-Signature'] || headers['HTTP_X_HUB_SIGNATURE']
        return unless request_signature

        signature_parts = request_signature.split("sha1=")
        request_signature = signature_parts[1]
        calculated_signature = OpenSSL::HMAC.hexdigest('sha1', @secret, body)
        calculated_signature == request_signature
      end

      # The Facebook subscription management URL for your application.
      def subscription_path
        @subscription_path ||= "#{@app_id}/subscriptions"
      end
    end
  end
end
