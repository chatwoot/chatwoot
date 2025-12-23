# frozen_string_literal: true

module OAuth
  # The RequestToken is used for the initial Request.
  # This is normally created by the Consumer object.
  class RequestToken < ConsumerToken
    # Generate an authorization URL for user authorization
    def authorize_url(params = nil)
      return nil if token.nil?

      params = (params || {}).merge(oauth_token: token)
      build_url(consumer.authorize_url, params)
    end

    def authenticate_url(params = nil)
      return nil if token.nil?

      params = (params || {}).merge(oauth_token: token)
      build_url(consumer.authenticate_url, params)
    end

    def callback_confirmed?
      params[:oauth_callback_confirmed] == "true"
    end

    # exchange for AccessToken on server
    def get_access_token(options = {}, *arguments)
      response = consumer.token_request(consumer.http_method,
                                        (consumer.access_token_url? ? consumer.access_token_url : consumer.access_token_path), self, options, *arguments)
      OAuth::AccessToken.from_hash(consumer, response)
    end

    protected

    # construct an authorization or authentication url
    def build_url(base_url, params)
      uri = URI.parse(base_url.to_s)
      queries = {}
      queries = URI.decode_www_form(uri.query).to_h if uri.query
      # TODO: doesn't handle array values correctly
      queries.merge!(params) if params
      uri.query = URI.encode_www_form(queries) unless queries.empty?
      uri.to_s
    end
  end
end
