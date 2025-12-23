# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SSOOIDC
  # @api private
  module ClientApi

    include Seahorse::Model

    AccessDeniedException = Shapes::StructureShape.new(name: 'AccessDeniedException')
    AccessToken = Shapes::StringShape.new(name: 'AccessToken')
    Assertion = Shapes::StringShape.new(name: 'Assertion')
    AuthCode = Shapes::StringShape.new(name: 'AuthCode')
    AuthorizationPendingException = Shapes::StructureShape.new(name: 'AuthorizationPendingException')
    ClientId = Shapes::StringShape.new(name: 'ClientId')
    ClientName = Shapes::StringShape.new(name: 'ClientName')
    ClientSecret = Shapes::StringShape.new(name: 'ClientSecret')
    ClientType = Shapes::StringShape.new(name: 'ClientType')
    CreateTokenRequest = Shapes::StructureShape.new(name: 'CreateTokenRequest')
    CreateTokenResponse = Shapes::StructureShape.new(name: 'CreateTokenResponse')
    CreateTokenWithIAMRequest = Shapes::StructureShape.new(name: 'CreateTokenWithIAMRequest')
    CreateTokenWithIAMResponse = Shapes::StructureShape.new(name: 'CreateTokenWithIAMResponse')
    DeviceCode = Shapes::StringShape.new(name: 'DeviceCode')
    Error = Shapes::StringShape.new(name: 'Error')
    ErrorDescription = Shapes::StringShape.new(name: 'ErrorDescription')
    ExpirationInSeconds = Shapes::IntegerShape.new(name: 'ExpirationInSeconds')
    ExpiredTokenException = Shapes::StructureShape.new(name: 'ExpiredTokenException')
    GrantType = Shapes::StringShape.new(name: 'GrantType')
    IdToken = Shapes::StringShape.new(name: 'IdToken')
    InternalServerException = Shapes::StructureShape.new(name: 'InternalServerException')
    IntervalInSeconds = Shapes::IntegerShape.new(name: 'IntervalInSeconds')
    InvalidClientException = Shapes::StructureShape.new(name: 'InvalidClientException')
    InvalidClientMetadataException = Shapes::StructureShape.new(name: 'InvalidClientMetadataException')
    InvalidGrantException = Shapes::StructureShape.new(name: 'InvalidGrantException')
    InvalidRequestException = Shapes::StructureShape.new(name: 'InvalidRequestException')
    InvalidRequestRegionException = Shapes::StructureShape.new(name: 'InvalidRequestRegionException')
    InvalidScopeException = Shapes::StructureShape.new(name: 'InvalidScopeException')
    Location = Shapes::StringShape.new(name: 'Location')
    LongTimeStampType = Shapes::IntegerShape.new(name: 'LongTimeStampType')
    RefreshToken = Shapes::StringShape.new(name: 'RefreshToken')
    Region = Shapes::StringShape.new(name: 'Region')
    RegisterClientRequest = Shapes::StructureShape.new(name: 'RegisterClientRequest')
    RegisterClientResponse = Shapes::StructureShape.new(name: 'RegisterClientResponse')
    Scope = Shapes::StringShape.new(name: 'Scope')
    Scopes = Shapes::ListShape.new(name: 'Scopes')
    SlowDownException = Shapes::StructureShape.new(name: 'SlowDownException')
    StartDeviceAuthorizationRequest = Shapes::StructureShape.new(name: 'StartDeviceAuthorizationRequest')
    StartDeviceAuthorizationResponse = Shapes::StructureShape.new(name: 'StartDeviceAuthorizationResponse')
    SubjectToken = Shapes::StringShape.new(name: 'SubjectToken')
    TokenType = Shapes::StringShape.new(name: 'TokenType')
    TokenTypeURI = Shapes::StringShape.new(name: 'TokenTypeURI')
    URI = Shapes::StringShape.new(name: 'URI')
    UnauthorizedClientException = Shapes::StructureShape.new(name: 'UnauthorizedClientException')
    UnsupportedGrantTypeException = Shapes::StructureShape.new(name: 'UnsupportedGrantTypeException')
    UserCode = Shapes::StringShape.new(name: 'UserCode')

    AccessDeniedException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    AccessDeniedException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    AccessDeniedException.struct_class = Types::AccessDeniedException

    AuthorizationPendingException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    AuthorizationPendingException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    AuthorizationPendingException.struct_class = Types::AuthorizationPendingException

    CreateTokenRequest.add_member(:client_id, Shapes::ShapeRef.new(shape: ClientId, required: true, location_name: "clientId"))
    CreateTokenRequest.add_member(:client_secret, Shapes::ShapeRef.new(shape: ClientSecret, required: true, location_name: "clientSecret"))
    CreateTokenRequest.add_member(:grant_type, Shapes::ShapeRef.new(shape: GrantType, required: true, location_name: "grantType"))
    CreateTokenRequest.add_member(:device_code, Shapes::ShapeRef.new(shape: DeviceCode, location_name: "deviceCode"))
    CreateTokenRequest.add_member(:code, Shapes::ShapeRef.new(shape: AuthCode, location_name: "code"))
    CreateTokenRequest.add_member(:refresh_token, Shapes::ShapeRef.new(shape: RefreshToken, location_name: "refreshToken"))
    CreateTokenRequest.add_member(:scope, Shapes::ShapeRef.new(shape: Scopes, location_name: "scope"))
    CreateTokenRequest.add_member(:redirect_uri, Shapes::ShapeRef.new(shape: URI, location_name: "redirectUri"))
    CreateTokenRequest.struct_class = Types::CreateTokenRequest

    CreateTokenResponse.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessToken, location_name: "accessToken"))
    CreateTokenResponse.add_member(:token_type, Shapes::ShapeRef.new(shape: TokenType, location_name: "tokenType"))
    CreateTokenResponse.add_member(:expires_in, Shapes::ShapeRef.new(shape: ExpirationInSeconds, location_name: "expiresIn"))
    CreateTokenResponse.add_member(:refresh_token, Shapes::ShapeRef.new(shape: RefreshToken, location_name: "refreshToken"))
    CreateTokenResponse.add_member(:id_token, Shapes::ShapeRef.new(shape: IdToken, location_name: "idToken"))
    CreateTokenResponse.struct_class = Types::CreateTokenResponse

    CreateTokenWithIAMRequest.add_member(:client_id, Shapes::ShapeRef.new(shape: ClientId, required: true, location_name: "clientId"))
    CreateTokenWithIAMRequest.add_member(:grant_type, Shapes::ShapeRef.new(shape: GrantType, required: true, location_name: "grantType"))
    CreateTokenWithIAMRequest.add_member(:code, Shapes::ShapeRef.new(shape: AuthCode, location_name: "code"))
    CreateTokenWithIAMRequest.add_member(:refresh_token, Shapes::ShapeRef.new(shape: RefreshToken, location_name: "refreshToken"))
    CreateTokenWithIAMRequest.add_member(:assertion, Shapes::ShapeRef.new(shape: Assertion, location_name: "assertion"))
    CreateTokenWithIAMRequest.add_member(:scope, Shapes::ShapeRef.new(shape: Scopes, location_name: "scope"))
    CreateTokenWithIAMRequest.add_member(:redirect_uri, Shapes::ShapeRef.new(shape: URI, location_name: "redirectUri"))
    CreateTokenWithIAMRequest.add_member(:subject_token, Shapes::ShapeRef.new(shape: SubjectToken, location_name: "subjectToken"))
    CreateTokenWithIAMRequest.add_member(:subject_token_type, Shapes::ShapeRef.new(shape: TokenTypeURI, location_name: "subjectTokenType"))
    CreateTokenWithIAMRequest.add_member(:requested_token_type, Shapes::ShapeRef.new(shape: TokenTypeURI, location_name: "requestedTokenType"))
    CreateTokenWithIAMRequest.struct_class = Types::CreateTokenWithIAMRequest

    CreateTokenWithIAMResponse.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessToken, location_name: "accessToken"))
    CreateTokenWithIAMResponse.add_member(:token_type, Shapes::ShapeRef.new(shape: TokenType, location_name: "tokenType"))
    CreateTokenWithIAMResponse.add_member(:expires_in, Shapes::ShapeRef.new(shape: ExpirationInSeconds, location_name: "expiresIn"))
    CreateTokenWithIAMResponse.add_member(:refresh_token, Shapes::ShapeRef.new(shape: RefreshToken, location_name: "refreshToken"))
    CreateTokenWithIAMResponse.add_member(:id_token, Shapes::ShapeRef.new(shape: IdToken, location_name: "idToken"))
    CreateTokenWithIAMResponse.add_member(:issued_token_type, Shapes::ShapeRef.new(shape: TokenTypeURI, location_name: "issuedTokenType"))
    CreateTokenWithIAMResponse.add_member(:scope, Shapes::ShapeRef.new(shape: Scopes, location_name: "scope"))
    CreateTokenWithIAMResponse.struct_class = Types::CreateTokenWithIAMResponse

    ExpiredTokenException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    ExpiredTokenException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    ExpiredTokenException.struct_class = Types::ExpiredTokenException

    InternalServerException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InternalServerException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InternalServerException.struct_class = Types::InternalServerException

    InvalidClientException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InvalidClientException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InvalidClientException.struct_class = Types::InvalidClientException

    InvalidClientMetadataException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InvalidClientMetadataException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InvalidClientMetadataException.struct_class = Types::InvalidClientMetadataException

    InvalidGrantException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InvalidGrantException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InvalidGrantException.struct_class = Types::InvalidGrantException

    InvalidRequestException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InvalidRequestException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InvalidRequestException.struct_class = Types::InvalidRequestException

    InvalidRequestRegionException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InvalidRequestRegionException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InvalidRequestRegionException.add_member(:endpoint, Shapes::ShapeRef.new(shape: Location, location_name: "endpoint"))
    InvalidRequestRegionException.add_member(:region, Shapes::ShapeRef.new(shape: Region, location_name: "region"))
    InvalidRequestRegionException.struct_class = Types::InvalidRequestRegionException

    InvalidScopeException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    InvalidScopeException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    InvalidScopeException.struct_class = Types::InvalidScopeException

    RegisterClientRequest.add_member(:client_name, Shapes::ShapeRef.new(shape: ClientName, required: true, location_name: "clientName"))
    RegisterClientRequest.add_member(:client_type, Shapes::ShapeRef.new(shape: ClientType, required: true, location_name: "clientType"))
    RegisterClientRequest.add_member(:scopes, Shapes::ShapeRef.new(shape: Scopes, location_name: "scopes"))
    RegisterClientRequest.struct_class = Types::RegisterClientRequest

    RegisterClientResponse.add_member(:client_id, Shapes::ShapeRef.new(shape: ClientId, location_name: "clientId"))
    RegisterClientResponse.add_member(:client_secret, Shapes::ShapeRef.new(shape: ClientSecret, location_name: "clientSecret"))
    RegisterClientResponse.add_member(:client_id_issued_at, Shapes::ShapeRef.new(shape: LongTimeStampType, location_name: "clientIdIssuedAt"))
    RegisterClientResponse.add_member(:client_secret_expires_at, Shapes::ShapeRef.new(shape: LongTimeStampType, location_name: "clientSecretExpiresAt"))
    RegisterClientResponse.add_member(:authorization_endpoint, Shapes::ShapeRef.new(shape: URI, location_name: "authorizationEndpoint"))
    RegisterClientResponse.add_member(:token_endpoint, Shapes::ShapeRef.new(shape: URI, location_name: "tokenEndpoint"))
    RegisterClientResponse.struct_class = Types::RegisterClientResponse

    Scopes.member = Shapes::ShapeRef.new(shape: Scope)

    SlowDownException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    SlowDownException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    SlowDownException.struct_class = Types::SlowDownException

    StartDeviceAuthorizationRequest.add_member(:client_id, Shapes::ShapeRef.new(shape: ClientId, required: true, location_name: "clientId"))
    StartDeviceAuthorizationRequest.add_member(:client_secret, Shapes::ShapeRef.new(shape: ClientSecret, required: true, location_name: "clientSecret"))
    StartDeviceAuthorizationRequest.add_member(:start_url, Shapes::ShapeRef.new(shape: URI, required: true, location_name: "startUrl"))
    StartDeviceAuthorizationRequest.struct_class = Types::StartDeviceAuthorizationRequest

    StartDeviceAuthorizationResponse.add_member(:device_code, Shapes::ShapeRef.new(shape: DeviceCode, location_name: "deviceCode"))
    StartDeviceAuthorizationResponse.add_member(:user_code, Shapes::ShapeRef.new(shape: UserCode, location_name: "userCode"))
    StartDeviceAuthorizationResponse.add_member(:verification_uri, Shapes::ShapeRef.new(shape: URI, location_name: "verificationUri"))
    StartDeviceAuthorizationResponse.add_member(:verification_uri_complete, Shapes::ShapeRef.new(shape: URI, location_name: "verificationUriComplete"))
    StartDeviceAuthorizationResponse.add_member(:expires_in, Shapes::ShapeRef.new(shape: ExpirationInSeconds, location_name: "expiresIn"))
    StartDeviceAuthorizationResponse.add_member(:interval, Shapes::ShapeRef.new(shape: IntervalInSeconds, location_name: "interval"))
    StartDeviceAuthorizationResponse.struct_class = Types::StartDeviceAuthorizationResponse

    UnauthorizedClientException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    UnauthorizedClientException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    UnauthorizedClientException.struct_class = Types::UnauthorizedClientException

    UnsupportedGrantTypeException.add_member(:error, Shapes::ShapeRef.new(shape: Error, location_name: "error"))
    UnsupportedGrantTypeException.add_member(:error_description, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "error_description"))
    UnsupportedGrantTypeException.struct_class = Types::UnsupportedGrantTypeException


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2019-06-10"

      api.metadata = {
        "apiVersion" => "2019-06-10",
        "endpointPrefix" => "oidc",
        "jsonVersion" => "1.1",
        "protocol" => "rest-json",
        "serviceAbbreviation" => "SSO OIDC",
        "serviceFullName" => "AWS SSO OIDC",
        "serviceId" => "SSO OIDC",
        "signatureVersion" => "v4",
        "signingName" => "sso-oauth",
        "uid" => "sso-oidc-2019-06-10",
      }

      api.add_operation(:create_token, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateToken"
        o.http_method = "POST"
        o.http_request_uri = "/token"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: CreateTokenRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateTokenResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidClientException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedClientException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedGrantTypeException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidScopeException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationPendingException)
        o.errors << Shapes::ShapeRef.new(shape: SlowDownException)
        o.errors << Shapes::ShapeRef.new(shape: AccessDeniedException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InternalServerException)
      end)

      api.add_operation(:create_token_with_iam, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateTokenWithIAM"
        o.http_method = "POST"
        o.http_request_uri = "/token?aws_iam=t"
        o.input = Shapes::ShapeRef.new(shape: CreateTokenWithIAMRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateTokenWithIAMResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidClientException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedClientException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedGrantTypeException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidScopeException)
        o.errors << Shapes::ShapeRef.new(shape: AuthorizationPendingException)
        o.errors << Shapes::ShapeRef.new(shape: SlowDownException)
        o.errors << Shapes::ShapeRef.new(shape: AccessDeniedException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InternalServerException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestRegionException)
      end)

      api.add_operation(:register_client, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RegisterClient"
        o.http_method = "POST"
        o.http_request_uri = "/client/register"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: RegisterClientRequest)
        o.output = Shapes::ShapeRef.new(shape: RegisterClientResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidScopeException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidClientMetadataException)
        o.errors << Shapes::ShapeRef.new(shape: InternalServerException)
      end)

      api.add_operation(:start_device_authorization, Seahorse::Model::Operation.new.tap do |o|
        o.name = "StartDeviceAuthorization"
        o.http_method = "POST"
        o.http_request_uri = "/device_authorization"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: StartDeviceAuthorizationRequest)
        o.output = Shapes::ShapeRef.new(shape: StartDeviceAuthorizationResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidClientException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedClientException)
        o.errors << Shapes::ShapeRef.new(shape: SlowDownException)
        o.errors << Shapes::ShapeRef.new(shape: InternalServerException)
      end)
    end

  end
end
