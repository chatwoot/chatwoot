# frozen_string_literal: true

require 'rack/media_type'

module Rack
  # Middleware that authenticates webhooks from Twilio using the request
  # validator.
  #
  # The middleware takes an auth token with which to set up the request
  # validator and any number of paths. When a path matches the incoming request
  # path, the request will be checked for authentication.
  #
  # Example:
  #
  # require 'rack'
  # use Rack::TwilioWebhookAuthentication, ENV['AUTH_TOKEN'], /\/messages/
  #
  # The above appends this middleware to the stack, using an auth token saved in
  # the ENV and only against paths that match /\/messages/. If the request
  # validates then it gets passed on to the action as normal. If the request
  # doesn't validate then the middleware responds immediately with a 403 status.

  class TwilioWebhookAuthentication
    # Rack's FORM_DATA_MEDIA_TYPES can be modified to taste, so we're slightly
    # more conservative in what we consider form data.
    FORM_URLENCODED_MEDIA_TYPE = Rack::MediaType.type('application/x-www-form-urlencoded')

    def initialize(app, auth_token, *paths, &auth_token_lookup)
      @app = app
      @auth_token = auth_token
      define_singleton_method(:get_auth_token, auth_token_lookup) if block_given?
      @path_regex = Regexp.union(paths)
    end

    def call(env)
      return @app.call(env) unless env['PATH_INFO'].match(@path_regex)
      request = Rack::Request.new(env)
      original_url = request.url
      params = extract_params!(request)
      auth_token = @auth_token || get_auth_token(params['AccountSid'])
      validator = Twilio::Security::RequestValidator.new(auth_token)
      signature = env['HTTP_X_TWILIO_SIGNATURE'] || ''
      if validator.validate(original_url, params, signature)
        @app.call(env)
      else
        [
          403,
          { 'Content-Type' => 'text/plain' },
          ['Twilio Request Validation Failed.']
        ]
      end
    end

    # Extract the params from the the request that we can use to determine the
    # signature. This _may_ modify the passed in request since it may read/rewind
    # the body.
    def extract_params!(request)
      return {} unless request.post?

      if request.media_type == FORM_URLENCODED_MEDIA_TYPE
        request.POST
      else
        request.body.rewind
        body = request.body.read
        request.body.rewind
        body
      end
    end

    private :extract_params!
  end
end
