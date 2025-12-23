# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SSOOIDC
  module Types

    # You do not have sufficient access to perform this action.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `access_denied`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/AccessDeniedException AWS API Documentation
    #
    class AccessDeniedException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a request to authorize a client with an access user
    # session token is pending.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `authorization_pending`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/AuthorizationPendingException AWS API Documentation
    #
    class AuthorizationPendingException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] client_id
    #   The unique identifier string for the client or application. This
    #   value comes from the result of the RegisterClient API.
    #   @return [String]
    #
    # @!attribute [rw] client_secret
    #   A secret string generated for the client. This value should come
    #   from the persisted result of the RegisterClient API.
    #   @return [String]
    #
    # @!attribute [rw] grant_type
    #   Supports the following OAuth grant types: Device Code and Refresh
    #   Token. Specify either of the following values, depending on the
    #   grant type that you want:
    #
    #   * Device Code - `urn:ietf:params:oauth:grant-type:device_code`
    #
    #   * Refresh Token - `refresh_token`
    #
    #   For information about how to obtain the device code, see the
    #   StartDeviceAuthorization topic.
    #   @return [String]
    #
    # @!attribute [rw] device_code
    #   Used only when calling this API for the Device Code grant type. This
    #   short-term code is used to identify this authorization request. This
    #   comes from the result of the StartDeviceAuthorization API.
    #   @return [String]
    #
    # @!attribute [rw] code
    #   Used only when calling this API for the Authorization Code grant
    #   type. The short-term code is used to identify this authorization
    #   request. This grant type is currently unsupported for the
    #   CreateToken API.
    #   @return [String]
    #
    # @!attribute [rw] refresh_token
    #   Used only when calling this API for the Refresh Token grant type.
    #   This token is used to refresh short-term tokens, such as the access
    #   token, that might expire.
    #
    #   For more information about the features and limitations of the
    #   current IAM Identity Center OIDC implementation, see *Considerations
    #   for Using this Guide* in the [IAM Identity Center OIDC API
    #   Reference][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/Welcome.html
    #   @return [String]
    #
    # @!attribute [rw] scope
    #   The list of scopes for which authorization is requested. The access
    #   token that is issued is limited to the scopes that are granted. If
    #   this value is not specified, IAM Identity Center authorizes all
    #   scopes that are configured for the client during the call to
    #   RegisterClient.
    #   @return [Array<String>]
    #
    # @!attribute [rw] redirect_uri
    #   Used only when calling this API for the Authorization Code grant
    #   type. This value specifies the location of the client or application
    #   that has registered to receive the authorization code.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/CreateTokenRequest AWS API Documentation
    #
    class CreateTokenRequest < Struct.new(
      :client_id,
      :client_secret,
      :grant_type,
      :device_code,
      :code,
      :refresh_token,
      :scope,
      :redirect_uri)
      SENSITIVE = [:client_secret, :refresh_token]
      include Aws::Structure
    end

    # @!attribute [rw] access_token
    #   A bearer token to access AWS accounts and applications assigned to a
    #   user.
    #   @return [String]
    #
    # @!attribute [rw] token_type
    #   Used to notify the client that the returned token is an access
    #   token. The supported token type is `Bearer`.
    #   @return [String]
    #
    # @!attribute [rw] expires_in
    #   Indicates the time in seconds when an access token will expire.
    #   @return [Integer]
    #
    # @!attribute [rw] refresh_token
    #   A token that, if present, can be used to refresh a previously issued
    #   access token that might have expired.
    #
    #   For more information about the features and limitations of the
    #   current IAM Identity Center OIDC implementation, see *Considerations
    #   for Using this Guide* in the [IAM Identity Center OIDC API
    #   Reference][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/Welcome.html
    #   @return [String]
    #
    # @!attribute [rw] id_token
    #   The `idToken` is not implemented or supported. For more information
    #   about the features and limitations of the current IAM Identity
    #   Center OIDC implementation, see *Considerations for Using this
    #   Guide* in the [IAM Identity Center OIDC API Reference][1].
    #
    #   A JSON Web Token (JWT) that identifies who is associated with the
    #   issued access token.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/Welcome.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/CreateTokenResponse AWS API Documentation
    #
    class CreateTokenResponse < Struct.new(
      :access_token,
      :token_type,
      :expires_in,
      :refresh_token,
      :id_token)
      SENSITIVE = [:access_token, :refresh_token, :id_token]
      include Aws::Structure
    end

    # @!attribute [rw] client_id
    #   The unique identifier string for the client or application. This
    #   value is an application ARN that has OAuth grants configured.
    #   @return [String]
    #
    # @!attribute [rw] grant_type
    #   Supports the following OAuth grant types: Authorization Code,
    #   Refresh Token, JWT Bearer, and Token Exchange. Specify one of the
    #   following values, depending on the grant type that you want:
    #
    #   * Authorization Code - `authorization_code`
    #
    #   * Refresh Token - `refresh_token`
    #
    #   * JWT Bearer - `urn:ietf:params:oauth:grant-type:jwt-bearer`
    #
    #   * Token Exchange -
    #   `urn:ietf:params:oauth:grant-type:token-exchange`
    #   @return [String]
    #
    # @!attribute [rw] code
    #   Used only when calling this API for the Authorization Code grant
    #   type. This short-term code is used to identify this authorization
    #   request. The code is obtained through a redirect from IAM Identity
    #   Center to a redirect URI persisted in the Authorization Code
    #   GrantOptions for the application.
    #   @return [String]
    #
    # @!attribute [rw] refresh_token
    #   Used only when calling this API for the Refresh Token grant type.
    #   This token is used to refresh short-term tokens, such as the access
    #   token, that might expire.
    #
    #   For more information about the features and limitations of the
    #   current IAM Identity Center OIDC implementation, see *Considerations
    #   for Using this Guide* in the [IAM Identity Center OIDC API
    #   Reference][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/Welcome.html
    #   @return [String]
    #
    # @!attribute [rw] assertion
    #   Used only when calling this API for the JWT Bearer grant type. This
    #   value specifies the JSON Web Token (JWT) issued by a trusted token
    #   issuer. To authorize a trusted token issuer, configure the JWT
    #   Bearer GrantOptions for the application.
    #   @return [String]
    #
    # @!attribute [rw] scope
    #   The list of scopes for which authorization is requested. The access
    #   token that is issued is limited to the scopes that are granted. If
    #   the value is not specified, IAM Identity Center authorizes all
    #   scopes configured for the application, including the following
    #   default scopes: `openid`, `aws`, `sts:identity_context`.
    #   @return [Array<String>]
    #
    # @!attribute [rw] redirect_uri
    #   Used only when calling this API for the Authorization Code grant
    #   type. This value specifies the location of the client or application
    #   that has registered to receive the authorization code.
    #   @return [String]
    #
    # @!attribute [rw] subject_token
    #   Used only when calling this API for the Token Exchange grant type.
    #   This value specifies the subject of the exchange. The value of the
    #   subject token must be an access token issued by IAM Identity Center
    #   to a different client or application. The access token must have
    #   authorized scopes that indicate the requested application as a
    #   target audience.
    #   @return [String]
    #
    # @!attribute [rw] subject_token_type
    #   Used only when calling this API for the Token Exchange grant type.
    #   This value specifies the type of token that is passed as the subject
    #   of the exchange. The following value is supported:
    #
    #   * Access Token - `urn:ietf:params:oauth:token-type:access_token`
    #   @return [String]
    #
    # @!attribute [rw] requested_token_type
    #   Used only when calling this API for the Token Exchange grant type.
    #   This value specifies the type of token that the requester can
    #   receive. The following values are supported:
    #
    #   * Access Token - `urn:ietf:params:oauth:token-type:access_token`
    #
    #   * Refresh Token - `urn:ietf:params:oauth:token-type:refresh_token`
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/CreateTokenWithIAMRequest AWS API Documentation
    #
    class CreateTokenWithIAMRequest < Struct.new(
      :client_id,
      :grant_type,
      :code,
      :refresh_token,
      :assertion,
      :scope,
      :redirect_uri,
      :subject_token,
      :subject_token_type,
      :requested_token_type)
      SENSITIVE = [:refresh_token, :assertion, :subject_token]
      include Aws::Structure
    end

    # @!attribute [rw] access_token
    #   A bearer token to access AWS accounts and applications assigned to a
    #   user.
    #   @return [String]
    #
    # @!attribute [rw] token_type
    #   Used to notify the requester that the returned token is an access
    #   token. The supported token type is `Bearer`.
    #   @return [String]
    #
    # @!attribute [rw] expires_in
    #   Indicates the time in seconds when an access token will expire.
    #   @return [Integer]
    #
    # @!attribute [rw] refresh_token
    #   A token that, if present, can be used to refresh a previously issued
    #   access token that might have expired.
    #
    #   For more information about the features and limitations of the
    #   current IAM Identity Center OIDC implementation, see *Considerations
    #   for Using this Guide* in the [IAM Identity Center OIDC API
    #   Reference][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/Welcome.html
    #   @return [String]
    #
    # @!attribute [rw] id_token
    #   A JSON Web Token (JWT) that identifies the user associated with the
    #   issued access token.
    #   @return [String]
    #
    # @!attribute [rw] issued_token_type
    #   Indicates the type of tokens that are issued by IAM Identity Center.
    #   The following values are supported:
    #
    #   * Access Token - `urn:ietf:params:oauth:token-type:access_token`
    #
    #   * Refresh Token - `urn:ietf:params:oauth:token-type:refresh_token`
    #   @return [String]
    #
    # @!attribute [rw] scope
    #   The list of scopes for which authorization is granted. The access
    #   token that is issued is limited to the scopes that are granted.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/CreateTokenWithIAMResponse AWS API Documentation
    #
    class CreateTokenWithIAMResponse < Struct.new(
      :access_token,
      :token_type,
      :expires_in,
      :refresh_token,
      :id_token,
      :issued_token_type,
      :scope)
      SENSITIVE = [:access_token, :refresh_token, :id_token]
      include Aws::Structure
    end

    # Indicates that the token issued by the service is expired and is no
    # longer valid.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `expired_token`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/ExpiredTokenException AWS API Documentation
    #
    class ExpiredTokenException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that an error from the service occurred while trying to
    # process a request.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `server_error`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InternalServerException AWS API Documentation
    #
    class InternalServerException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the `clientId` or `clientSecret` in the request is
    # invalid. For example, this can occur when a client sends an incorrect
    # `clientId` or an expired `clientSecret`.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `invalid_client`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InvalidClientException AWS API Documentation
    #
    class InvalidClientException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the client information sent in the request during
    # registration is invalid.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `invalid_client_metadata`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InvalidClientMetadataException AWS API Documentation
    #
    class InvalidClientMetadataException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a request contains an invalid grant. This can occur if
    # a client makes a CreateToken request with an invalid grant type.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `invalid_grant`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InvalidGrantException AWS API Documentation
    #
    class InvalidGrantException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that something is wrong with the input to the request. For
    # example, a required parameter might be missing or out of range.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `invalid_request`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InvalidRequestException AWS API Documentation
    #
    class InvalidRequestException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a token provided as input to the request was issued by
    # and is only usable by calling IAM Identity Center endpoints in another
    # region.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `invalid_request`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @!attribute [rw] endpoint
    #   Indicates the IAM Identity Center endpoint which the requester may
    #   call with this token.
    #   @return [String]
    #
    # @!attribute [rw] region
    #   Indicates the region which the requester may call with this token.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InvalidRequestRegionException AWS API Documentation
    #
    class InvalidRequestRegionException < Struct.new(
      :error,
      :error_description,
      :endpoint,
      :region)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the scope provided in the request is invalid.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `invalid_scope`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/InvalidScopeException AWS API Documentation
    #
    class InvalidScopeException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] client_name
    #   The friendly name of the client.
    #   @return [String]
    #
    # @!attribute [rw] client_type
    #   The type of client. The service supports only `public` as a client
    #   type. Anything other than public will be rejected by the service.
    #   @return [String]
    #
    # @!attribute [rw] scopes
    #   The list of scopes that are defined by the client. Upon
    #   authorization, this list is used to restrict permissions when
    #   granting an access token.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/RegisterClientRequest AWS API Documentation
    #
    class RegisterClientRequest < Struct.new(
      :client_name,
      :client_type,
      :scopes)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] client_id
    #   The unique identifier string for each client. This client uses this
    #   identifier to get authenticated by the service in subsequent calls.
    #   @return [String]
    #
    # @!attribute [rw] client_secret
    #   A secret string generated for the client. The client will use this
    #   string to get authenticated by the service in subsequent calls.
    #   @return [String]
    #
    # @!attribute [rw] client_id_issued_at
    #   Indicates the time at which the `clientId` and `clientSecret` were
    #   issued.
    #   @return [Integer]
    #
    # @!attribute [rw] client_secret_expires_at
    #   Indicates the time at which the `clientId` and `clientSecret` will
    #   become invalid.
    #   @return [Integer]
    #
    # @!attribute [rw] authorization_endpoint
    #   An endpoint that the client can use to request authorization.
    #   @return [String]
    #
    # @!attribute [rw] token_endpoint
    #   An endpoint that the client can use to create tokens.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/RegisterClientResponse AWS API Documentation
    #
    class RegisterClientResponse < Struct.new(
      :client_id,
      :client_secret,
      :client_id_issued_at,
      :client_secret_expires_at,
      :authorization_endpoint,
      :token_endpoint)
      SENSITIVE = [:client_secret]
      include Aws::Structure
    end

    # Indicates that the client is making the request too frequently and is
    # more than the service can handle.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be `slow_down`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/SlowDownException AWS API Documentation
    #
    class SlowDownException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] client_id
    #   The unique identifier string for the client that is registered with
    #   IAM Identity Center. This value should come from the persisted
    #   result of the RegisterClient API operation.
    #   @return [String]
    #
    # @!attribute [rw] client_secret
    #   A secret string that is generated for the client. This value should
    #   come from the persisted result of the RegisterClient API operation.
    #   @return [String]
    #
    # @!attribute [rw] start_url
    #   The URL for the Amazon Web Services access portal. For more
    #   information, see [Using the Amazon Web Services access portal][1] in
    #   the *IAM Identity Center User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/userguide/using-the-portal.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/StartDeviceAuthorizationRequest AWS API Documentation
    #
    class StartDeviceAuthorizationRequest < Struct.new(
      :client_id,
      :client_secret,
      :start_url)
      SENSITIVE = [:client_secret]
      include Aws::Structure
    end

    # @!attribute [rw] device_code
    #   The short-lived code that is used by the device when polling for a
    #   session token.
    #   @return [String]
    #
    # @!attribute [rw] user_code
    #   A one-time user verification code. This is needed to authorize an
    #   in-use device.
    #   @return [String]
    #
    # @!attribute [rw] verification_uri
    #   The URI of the verification page that takes the `userCode` to
    #   authorize the device.
    #   @return [String]
    #
    # @!attribute [rw] verification_uri_complete
    #   An alternate URL that the client can use to automatically launch a
    #   browser. This process skips the manual step in which the user visits
    #   the verification page and enters their code.
    #   @return [String]
    #
    # @!attribute [rw] expires_in
    #   Indicates the number of seconds in which the verification code will
    #   become invalid.
    #   @return [Integer]
    #
    # @!attribute [rw] interval
    #   Indicates the number of seconds the client must wait between
    #   attempts when polling for a session.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/StartDeviceAuthorizationResponse AWS API Documentation
    #
    class StartDeviceAuthorizationResponse < Struct.new(
      :device_code,
      :user_code,
      :verification_uri,
      :verification_uri_complete,
      :expires_in,
      :interval)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the client is not currently authorized to make the
    # request. This can happen when a `clientId` is not issued for a public
    # client.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `unauthorized_client`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/UnauthorizedClientException AWS API Documentation
    #
    class UnauthorizedClientException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the grant type in the request is not supported by the
    # service.
    #
    # @!attribute [rw] error
    #   Single error code. For this exception the value will be
    #   `unsupported_grant_type`.
    #   @return [String]
    #
    # @!attribute [rw] error_description
    #   Human-readable text providing additional information, used to assist
    #   the client developer in understanding the error that occurred.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-oidc-2019-06-10/UnsupportedGrantTypeException AWS API Documentation
    #
    class UnsupportedGrantTypeException < Struct.new(
      :error,
      :error_description)
      SENSITIVE = []
      include Aws::Structure
    end

  end
end
