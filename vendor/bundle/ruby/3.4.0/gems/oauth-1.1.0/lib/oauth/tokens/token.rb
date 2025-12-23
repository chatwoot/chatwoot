# frozen_string_literal: true

module OAuth
  # Superclass for the various tokens used by OAuth
  class Token
    include OAuth::Helper

    attr_accessor :token, :secret

    def initialize(token, secret)
      @token = token
      @secret = secret
    end

    def to_query
      "oauth_token=#{escape(token)}&oauth_token_secret=#{escape(secret)}"
    end
  end
end
