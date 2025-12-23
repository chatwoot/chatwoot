# frozen_string_literal: true

module Stripe
  class OAuthService < StripeService
    def authorize_url(params = {}, opts = {})
      path = if opts[:express]
               "/express/oauth/authorize"
             else
               "/oauth/authorize"
             end

      params[:client_id] = client_id(params)

      params[:response_type] = "code" if params.include?(:response_type)

      query = Util.encode_parameters(params, :v1)

      connect_api_base = @requestor.config.base_addresses[:connect]
      raise ArgumentError, "connect_api_base cannot be empty" if connect_api_base.nil? || connect_api_base.empty?

      "#{connect_api_base}#{path}?#{query}"
    end

    def token(params = {}, opts = {})
      opts = Util.normalize_opts(opts)
      opts[:api_key] = params[:client_secret] if params[:client_secret]

      request(
        method: :post,
        path: "/oauth/token",
        params: params,
        opts: opts,
        base_address: :connect
      )
    end

    def deauthorize(params = {}, opts = {})
      params[:client_id] = client_id(params)

      request(
        method: :post,
        path: "/oauth/deauthorize",
        params: params,
        opts: opts,
        base_address: :connect
      )
    end

    private def client_id(params = {})
      return params[:client_id] if params.include?(:client_id)

      return @requestor.config.client_id if !@requestor.config.client_id.nil? && !@requestor.config.client_id.empty?

      raise AuthenticationError, "No client_id provided. (HINT: set your client_id when configuring " \
                                 "your StripeClient: \"Stripe::StripeClient.new(..., client_id: <CLIENT_ID>)\"). " \
                                 "You can find your client_ids in your Stripe dashboard at " \
                                 "https://dashboard.stripe.com/account/applications/settings, " \
                                 "after registering your account as a platform. See " \
                                 "https://stripe.com/docs/connect/standalone-accounts for details, " \
                                 "or email support@stripe.com if you have any questions." \
    end
  end
end
