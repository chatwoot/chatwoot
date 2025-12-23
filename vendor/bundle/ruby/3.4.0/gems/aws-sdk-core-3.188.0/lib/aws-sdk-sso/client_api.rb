# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SSO
  # @api private
  module ClientApi

    include Seahorse::Model

    AccessKeyType = Shapes::StringShape.new(name: 'AccessKeyType')
    AccessTokenType = Shapes::StringShape.new(name: 'AccessTokenType')
    AccountIdType = Shapes::StringShape.new(name: 'AccountIdType')
    AccountInfo = Shapes::StructureShape.new(name: 'AccountInfo')
    AccountListType = Shapes::ListShape.new(name: 'AccountListType')
    AccountNameType = Shapes::StringShape.new(name: 'AccountNameType')
    EmailAddressType = Shapes::StringShape.new(name: 'EmailAddressType')
    ErrorDescription = Shapes::StringShape.new(name: 'ErrorDescription')
    ExpirationTimestampType = Shapes::IntegerShape.new(name: 'ExpirationTimestampType')
    GetRoleCredentialsRequest = Shapes::StructureShape.new(name: 'GetRoleCredentialsRequest')
    GetRoleCredentialsResponse = Shapes::StructureShape.new(name: 'GetRoleCredentialsResponse')
    InvalidRequestException = Shapes::StructureShape.new(name: 'InvalidRequestException')
    ListAccountRolesRequest = Shapes::StructureShape.new(name: 'ListAccountRolesRequest')
    ListAccountRolesResponse = Shapes::StructureShape.new(name: 'ListAccountRolesResponse')
    ListAccountsRequest = Shapes::StructureShape.new(name: 'ListAccountsRequest')
    ListAccountsResponse = Shapes::StructureShape.new(name: 'ListAccountsResponse')
    LogoutRequest = Shapes::StructureShape.new(name: 'LogoutRequest')
    MaxResultType = Shapes::IntegerShape.new(name: 'MaxResultType')
    NextTokenType = Shapes::StringShape.new(name: 'NextTokenType')
    ResourceNotFoundException = Shapes::StructureShape.new(name: 'ResourceNotFoundException')
    RoleCredentials = Shapes::StructureShape.new(name: 'RoleCredentials')
    RoleInfo = Shapes::StructureShape.new(name: 'RoleInfo')
    RoleListType = Shapes::ListShape.new(name: 'RoleListType')
    RoleNameType = Shapes::StringShape.new(name: 'RoleNameType')
    SecretAccessKeyType = Shapes::StringShape.new(name: 'SecretAccessKeyType')
    SessionTokenType = Shapes::StringShape.new(name: 'SessionTokenType')
    TooManyRequestsException = Shapes::StructureShape.new(name: 'TooManyRequestsException')
    UnauthorizedException = Shapes::StructureShape.new(name: 'UnauthorizedException')

    AccountInfo.add_member(:account_id, Shapes::ShapeRef.new(shape: AccountIdType, location_name: "accountId"))
    AccountInfo.add_member(:account_name, Shapes::ShapeRef.new(shape: AccountNameType, location_name: "accountName"))
    AccountInfo.add_member(:email_address, Shapes::ShapeRef.new(shape: EmailAddressType, location_name: "emailAddress"))
    AccountInfo.struct_class = Types::AccountInfo

    AccountListType.member = Shapes::ShapeRef.new(shape: AccountInfo)

    GetRoleCredentialsRequest.add_member(:role_name, Shapes::ShapeRef.new(shape: RoleNameType, required: true, location: "querystring", location_name: "role_name"))
    GetRoleCredentialsRequest.add_member(:account_id, Shapes::ShapeRef.new(shape: AccountIdType, required: true, location: "querystring", location_name: "account_id"))
    GetRoleCredentialsRequest.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessTokenType, required: true, location: "header", location_name: "x-amz-sso_bearer_token"))
    GetRoleCredentialsRequest.struct_class = Types::GetRoleCredentialsRequest

    GetRoleCredentialsResponse.add_member(:role_credentials, Shapes::ShapeRef.new(shape: RoleCredentials, location_name: "roleCredentials"))
    GetRoleCredentialsResponse.struct_class = Types::GetRoleCredentialsResponse

    InvalidRequestException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "message"))
    InvalidRequestException.struct_class = Types::InvalidRequestException

    ListAccountRolesRequest.add_member(:next_token, Shapes::ShapeRef.new(shape: NextTokenType, location: "querystring", location_name: "next_token"))
    ListAccountRolesRequest.add_member(:max_results, Shapes::ShapeRef.new(shape: MaxResultType, location: "querystring", location_name: "max_result"))
    ListAccountRolesRequest.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessTokenType, required: true, location: "header", location_name: "x-amz-sso_bearer_token"))
    ListAccountRolesRequest.add_member(:account_id, Shapes::ShapeRef.new(shape: AccountIdType, required: true, location: "querystring", location_name: "account_id"))
    ListAccountRolesRequest.struct_class = Types::ListAccountRolesRequest

    ListAccountRolesResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: NextTokenType, location_name: "nextToken"))
    ListAccountRolesResponse.add_member(:role_list, Shapes::ShapeRef.new(shape: RoleListType, location_name: "roleList"))
    ListAccountRolesResponse.struct_class = Types::ListAccountRolesResponse

    ListAccountsRequest.add_member(:next_token, Shapes::ShapeRef.new(shape: NextTokenType, location: "querystring", location_name: "next_token"))
    ListAccountsRequest.add_member(:max_results, Shapes::ShapeRef.new(shape: MaxResultType, location: "querystring", location_name: "max_result"))
    ListAccountsRequest.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessTokenType, required: true, location: "header", location_name: "x-amz-sso_bearer_token"))
    ListAccountsRequest.struct_class = Types::ListAccountsRequest

    ListAccountsResponse.add_member(:next_token, Shapes::ShapeRef.new(shape: NextTokenType, location_name: "nextToken"))
    ListAccountsResponse.add_member(:account_list, Shapes::ShapeRef.new(shape: AccountListType, location_name: "accountList"))
    ListAccountsResponse.struct_class = Types::ListAccountsResponse

    LogoutRequest.add_member(:access_token, Shapes::ShapeRef.new(shape: AccessTokenType, required: true, location: "header", location_name: "x-amz-sso_bearer_token"))
    LogoutRequest.struct_class = Types::LogoutRequest

    ResourceNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "message"))
    ResourceNotFoundException.struct_class = Types::ResourceNotFoundException

    RoleCredentials.add_member(:access_key_id, Shapes::ShapeRef.new(shape: AccessKeyType, location_name: "accessKeyId"))
    RoleCredentials.add_member(:secret_access_key, Shapes::ShapeRef.new(shape: SecretAccessKeyType, location_name: "secretAccessKey"))
    RoleCredentials.add_member(:session_token, Shapes::ShapeRef.new(shape: SessionTokenType, location_name: "sessionToken"))
    RoleCredentials.add_member(:expiration, Shapes::ShapeRef.new(shape: ExpirationTimestampType, location_name: "expiration"))
    RoleCredentials.struct_class = Types::RoleCredentials

    RoleInfo.add_member(:role_name, Shapes::ShapeRef.new(shape: RoleNameType, location_name: "roleName"))
    RoleInfo.add_member(:account_id, Shapes::ShapeRef.new(shape: AccountIdType, location_name: "accountId"))
    RoleInfo.struct_class = Types::RoleInfo

    RoleListType.member = Shapes::ShapeRef.new(shape: RoleInfo)

    TooManyRequestsException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "message"))
    TooManyRequestsException.struct_class = Types::TooManyRequestsException

    UnauthorizedException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorDescription, location_name: "message"))
    UnauthorizedException.struct_class = Types::UnauthorizedException


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2019-06-10"

      api.metadata = {
        "apiVersion" => "2019-06-10",
        "endpointPrefix" => "portal.sso",
        "jsonVersion" => "1.1",
        "protocol" => "rest-json",
        "serviceAbbreviation" => "SSO",
        "serviceFullName" => "AWS Single Sign-On",
        "serviceId" => "SSO",
        "signatureVersion" => "v4",
        "signingName" => "awsssoportal",
        "uid" => "sso-2019-06-10",
      }

      api.add_operation(:get_role_credentials, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetRoleCredentials"
        o.http_method = "GET"
        o.http_request_uri = "/federation/credentials"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: GetRoleCredentialsRequest)
        o.output = Shapes::ShapeRef.new(shape: GetRoleCredentialsResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedException)
        o.errors << Shapes::ShapeRef.new(shape: TooManyRequestsException)
        o.errors << Shapes::ShapeRef.new(shape: ResourceNotFoundException)
      end)

      api.add_operation(:list_account_roles, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListAccountRoles"
        o.http_method = "GET"
        o.http_request_uri = "/assignment/roles"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: ListAccountRolesRequest)
        o.output = Shapes::ShapeRef.new(shape: ListAccountRolesResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedException)
        o.errors << Shapes::ShapeRef.new(shape: TooManyRequestsException)
        o.errors << Shapes::ShapeRef.new(shape: ResourceNotFoundException)
        o[:pager] = Aws::Pager.new(
          limit_key: "max_results",
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:list_accounts, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListAccounts"
        o.http_method = "GET"
        o.http_request_uri = "/assignment/accounts"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: ListAccountsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListAccountsResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedException)
        o.errors << Shapes::ShapeRef.new(shape: TooManyRequestsException)
        o.errors << Shapes::ShapeRef.new(shape: ResourceNotFoundException)
        o[:pager] = Aws::Pager.new(
          limit_key: "max_results",
          tokens: {
            "next_token" => "next_token"
          }
        )
      end)

      api.add_operation(:logout, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Logout"
        o.http_method = "POST"
        o.http_request_uri = "/logout"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: LogoutRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidRequestException)
        o.errors << Shapes::ShapeRef.new(shape: UnauthorizedException)
        o.errors << Shapes::ShapeRef.new(shape: TooManyRequestsException)
      end)
    end

  end
end
