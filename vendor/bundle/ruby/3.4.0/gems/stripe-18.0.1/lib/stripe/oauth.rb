# frozen_string_literal: true

module Stripe
  module OAuth
    module OAuthOperations
      extend APIOperations::Request::ClassMethods

      def self.execute_resource_request(method, url, base_address, params, opts)
        opts = Util.normalize_opts(opts)

        super
      end
    end

    def self.get_client_id(params = {})
      client_id = params[:client_id] || Stripe.client_id
      unless client_id
        raise AuthenticationError, "No client_id provided. " \
                                   'Set your client_id using "Stripe.client_id = <CLIENT-ID>". ' \
                                   "You can find your client_ids in your Stripe dashboard at " \
                                   "https://dashboard.stripe.com/account/applications/settings, " \
                                   "after registering your account as a platform. See " \
                                   "https://stripe.com/docs/connect/standalone-accounts for details, " \
                                   "or email support@stripe.com if you have any questions."
      end
      client_id
    end

    def self.authorize_url(params = {}, opts = {})
      base = opts[:connect_base] || APIRequestor.active_requestor.config.connect_base

      path = "/oauth/authorize"
      path = "/express" + path if opts[:express]

      params[:client_id] = get_client_id(params)
      params[:response_type] ||= "code"
      query = Util.encode_parameters(params, :v1)

      "#{base}#{path}?#{query}"
    end

    def self.token(params = {}, opts = {})
      opts = Util.normalize_opts(opts)
      opts[:api_key] = params[:client_secret] if params[:client_secret]
      OAuthOperations.execute_resource_request(
        :post, "/oauth/token", :connect, params, opts
      )
    end

    def self.deauthorize(params = {}, opts = {})
      opts = Util.normalize_opts(opts)
      params[:client_id] = get_client_id(params)
      OAuthOperations.execute_resource_request(
        :post, "/oauth/deauthorize", :connect, params, opts
      )
    end
  end
end
