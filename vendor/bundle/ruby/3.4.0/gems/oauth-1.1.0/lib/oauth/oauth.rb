# frozen_string_literal: true

module OAuth
  # request tokens are passed between the consumer and the provider out of
  # band (i.e. callbacks cannot be used), per section 6.1.1
  OUT_OF_BAND = "oob"

  # required parameters, per sections 6.1.1, 6.3.1, and 7
  PARAMETERS = %w[oauth_callback oauth_consumer_key oauth_token
                  oauth_signature_method oauth_timestamp oauth_nonce oauth_verifier
                  oauth_version oauth_signature oauth_body_hash].freeze

  # reserved character regexp, per section 5.1
  RESERVED_CHARACTERS = /[^a-zA-Z0-9\-._~]/.freeze
end
