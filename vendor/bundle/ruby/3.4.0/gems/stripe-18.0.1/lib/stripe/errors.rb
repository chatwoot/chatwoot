# frozen_string_literal: true

module Stripe
  # StripeError is the base error from which all other more specific Stripe
  # errors derive.
  class StripeError < StandardError
    attr_reader :message, :code, :error, :http_body, :http_headers, :http_status, :json_body, :request_id

    # Response contains a StripeResponse object that has some basic information
    # about the response that conveyed the error.
    attr_accessor :response # equivalent to #data

    # Initializes a StripeError.
    def initialize(message = nil, http_status: nil, http_body: nil, # rubocop:todo Lint/MissingSuper
                   json_body: nil, http_headers: nil, code: nil)
      @message = message
      @http_status = http_status
      @http_body = http_body
      @http_headers = http_headers || {}
      @idempotent_replayed = @http_headers["idempotent-replayed"] == "true"
      @json_body = json_body
      @code = code
      @request_id = @http_headers["request-id"]
      @error = construct_error_object
    end

    def construct_error_object
      return nil if @json_body.nil? || !@json_body.key?(:error)

      # ErrorObject is shared between v1 and v2, so use original object_classes to find
      ErrorObject.construct_from(@json_body[:error], {}, nil, :v1)
    end

    def to_s
      status_string = @http_status.nil? ? "" : "(Status #{@http_status}) "
      id_string = @request_id.nil? ? "" : "(Request #{@request_id}) "
      "#{status_string}#{id_string}#{@message}"
    end
  end

  # AuthenticationError is raised when invalid credentials are used to connect
  # to Stripe's servers.
  class AuthenticationError < StripeError
  end

  # APIConnectionError is raised in the event that the SDK can't connect to
  # Stripe's servers. That can be for a variety of different reasons from a
  # downed network to a bad TLS certificate.
  class APIConnectionError < StripeError
  end

  # APIError is a generic error that may be raised in cases where none of the
  # other named errors cover the problem. It could also be raised in the case
  # that a new error has been introduced in the API, but this version of the
  # Ruby SDK doesn't know how to handle it.
  class APIError < StripeError
  end

  # CardError is raised when a user enters a card that can't be charged for
  # some reason.
  class CardError < StripeError
    attr_reader :param

    def initialize(message, param, code: nil, http_status: nil, http_body: nil,
                   json_body: nil, http_headers: nil)
      super(message, http_status: http_status, http_body: http_body,
                     json_body: json_body, http_headers: http_headers,
                     code: code)
      @param = param
    end
  end

  # IdempotencyError is raised in cases where an idempotency key was used
  # improperly.
  class IdempotencyError < StripeError
  end

  # InvalidRequestError is raised when a request is initiated with invalid
  # parameters.
  class InvalidRequestError < StripeError
    attr_accessor :param

    def initialize(message, param, http_status: nil, http_body: nil,
                   json_body: nil, http_headers: nil, code: nil)
      super(message, http_status: http_status, http_body: http_body,
                     json_body: json_body, http_headers: http_headers,
                     code: code)
      @param = param
    end
  end

  # PermissionError is raised in cases where access was attempted on a resource
  # that wasn't allowed.
  class PermissionError < StripeError
  end

  # RateLimitError is raised in cases where an account is putting too much load
  # on Stripe's API servers (usually by performing too many requests). Please
  # back off on request rate.
  class RateLimitError < StripeError
  end

  # SignatureVerificationError is raised when the signature verification for a
  # webhook fails
  class SignatureVerificationError < StripeError
    attr_accessor :sig_header

    def initialize(message, sig_header, http_body: nil)
      super(message, http_body: http_body)
      @sig_header = sig_header
    end
  end

  module OAuth
    # OAuthError is raised when the OAuth API returns an error.
    class OAuthError < StripeError
      def initialize(code, description, http_status: nil, http_body: nil,
                     json_body: nil, http_headers: nil)
        super(description, http_status: http_status, http_body: http_body,
                           json_body: json_body, http_headers: http_headers,
                           code: code)
      end

      def construct_error_object
        return nil if @json_body.nil?

        OAuthErrorObject.construct_from(@json_body, {}, nil, :v1)
      end
    end

    # InvalidClientError is raised when the client doesn't belong to you, or
    # the API key mode (live or test) doesn't match the client mode. Or the
    # stripe_user_id doesn't exist or isn't connected to your application.
    class InvalidClientError < OAuthError
    end

    # InvalidGrantError is raised when a specified code doesn't exist, is
    # expired, has been used, or doesn't belong to you; a refresh token doesn't
    # exist, or doesn't belong to you; or if an API key's mode (live or test)
    # doesn't match the mode of a code or refresh token.
    class InvalidGrantError < OAuthError
    end

    # InvalidRequestError is raised when a code, refresh token, or grant type
    # parameter is not provided, but was required.
    class InvalidRequestError < OAuthError
    end

    # InvalidScopeError is raised when an invalid scope parameter is provided.
    class InvalidScopeError < OAuthError
    end

    # UnsupportedGrantTypeError is raised when an unuspported grant type
    # parameter is specified.
    class UnsupportedGrantTypeError < OAuthError
    end

    # UnsupportedResponseTypeError is raised when an unsupported response type
    # parameter is specified.
    class UnsupportedResponseTypeError < OAuthError
    end
  end

  # class definitions: The beginning of the section generated from our OpenAPI spec
  class TemporarySessionExpiredError < StripeError
  end
  # class definitions: The end of the section generated from our OpenAPI spec
end
