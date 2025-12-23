# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SSO
  module Types

    # Provides information about your AWS account.
    #
    # @!attribute [rw] account_id
    #   The identifier of the AWS account that is assigned to the user.
    #   @return [String]
    #
    # @!attribute [rw] account_name
    #   The display name of the AWS account that is assigned to the user.
    #   @return [String]
    #
    # @!attribute [rw] email_address
    #   The email address of the AWS account that is assigned to the user.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/AccountInfo AWS API Documentation
    #
    class AccountInfo < Struct.new(
      :account_id,
      :account_name,
      :email_address)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] role_name
    #   The friendly name of the role that is assigned to the user.
    #   @return [String]
    #
    # @!attribute [rw] account_id
    #   The identifier for the AWS account that is assigned to the user.
    #   @return [String]
    #
    # @!attribute [rw] access_token
    #   The token issued by the `CreateToken` API call. For more
    #   information, see [CreateToken][1] in the *IAM Identity Center OIDC
    #   API Reference Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/GetRoleCredentialsRequest AWS API Documentation
    #
    class GetRoleCredentialsRequest < Struct.new(
      :role_name,
      :account_id,
      :access_token)
      SENSITIVE = [:access_token]
      include Aws::Structure
    end

    # @!attribute [rw] role_credentials
    #   The credentials for the role that is assigned to the user.
    #   @return [Types::RoleCredentials]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/GetRoleCredentialsResponse AWS API Documentation
    #
    class GetRoleCredentialsResponse < Struct.new(
      :role_credentials)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a problem occurred with the input to the request. For
    # example, a required parameter might be missing or out of range.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/InvalidRequestException AWS API Documentation
    #
    class InvalidRequestException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   The page token from the previous response output when you request
    #   subsequent pages.
    #   @return [String]
    #
    # @!attribute [rw] max_results
    #   The number of items that clients can request per page.
    #   @return [Integer]
    #
    # @!attribute [rw] access_token
    #   The token issued by the `CreateToken` API call. For more
    #   information, see [CreateToken][1] in the *IAM Identity Center OIDC
    #   API Reference Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html
    #   @return [String]
    #
    # @!attribute [rw] account_id
    #   The identifier for the AWS account that is assigned to the user.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/ListAccountRolesRequest AWS API Documentation
    #
    class ListAccountRolesRequest < Struct.new(
      :next_token,
      :max_results,
      :access_token,
      :account_id)
      SENSITIVE = [:access_token]
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   The page token client that is used to retrieve the list of accounts.
    #   @return [String]
    #
    # @!attribute [rw] role_list
    #   A paginated response with the list of roles and the next token if
    #   more results are available.
    #   @return [Array<Types::RoleInfo>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/ListAccountRolesResponse AWS API Documentation
    #
    class ListAccountRolesResponse < Struct.new(
      :next_token,
      :role_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   (Optional) When requesting subsequent pages, this is the page token
    #   from the previous response output.
    #   @return [String]
    #
    # @!attribute [rw] max_results
    #   This is the number of items clients can request per page.
    #   @return [Integer]
    #
    # @!attribute [rw] access_token
    #   The token issued by the `CreateToken` API call. For more
    #   information, see [CreateToken][1] in the *IAM Identity Center OIDC
    #   API Reference Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/ListAccountsRequest AWS API Documentation
    #
    class ListAccountsRequest < Struct.new(
      :next_token,
      :max_results,
      :access_token)
      SENSITIVE = [:access_token]
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   The page token client that is used to retrieve the list of accounts.
    #   @return [String]
    #
    # @!attribute [rw] account_list
    #   A paginated response with the list of account information and the
    #   next token if more results are available.
    #   @return [Array<Types::AccountInfo>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/ListAccountsResponse AWS API Documentation
    #
    class ListAccountsResponse < Struct.new(
      :next_token,
      :account_list)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] access_token
    #   The token issued by the `CreateToken` API call. For more
    #   information, see [CreateToken][1] in the *IAM Identity Center OIDC
    #   API Reference Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/LogoutRequest AWS API Documentation
    #
    class LogoutRequest < Struct.new(
      :access_token)
      SENSITIVE = [:access_token]
      include Aws::Structure
    end

    # The specified resource doesn't exist.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/ResourceNotFoundException AWS API Documentation
    #
    class ResourceNotFoundException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Provides information about the role credentials that are assigned to
    # the user.
    #
    # @!attribute [rw] access_key_id
    #   The identifier used for the temporary security credentials. For more
    #   information, see [Using Temporary Security Credentials to Request
    #   Access to AWS Resources][1] in the *AWS IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html
    #   @return [String]
    #
    # @!attribute [rw] secret_access_key
    #   The key that is used to sign the request. For more information, see
    #   [Using Temporary Security Credentials to Request Access to AWS
    #   Resources][1] in the *AWS IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html
    #   @return [String]
    #
    # @!attribute [rw] session_token
    #   The token used for temporary credentials. For more information, see
    #   [Using Temporary Security Credentials to Request Access to AWS
    #   Resources][1] in the *AWS IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   The date on which temporary security credentials expire.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/RoleCredentials AWS API Documentation
    #
    class RoleCredentials < Struct.new(
      :access_key_id,
      :secret_access_key,
      :session_token,
      :expiration)
      SENSITIVE = [:secret_access_key, :session_token]
      include Aws::Structure
    end

    # Provides information about the role that is assigned to the user.
    #
    # @!attribute [rw] role_name
    #   The friendly name of the role that is assigned to the user.
    #   @return [String]
    #
    # @!attribute [rw] account_id
    #   The identifier of the AWS account assigned to the user.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/RoleInfo AWS API Documentation
    #
    class RoleInfo < Struct.new(
      :role_name,
      :account_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the request is being made too frequently and is more
    # than what the server can handle.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/TooManyRequestsException AWS API Documentation
    #
    class TooManyRequestsException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the request is not authorized. This can happen due to
    # an invalid access token in the request.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sso-2019-06-10/UnauthorizedException AWS API Documentation
    #
    class UnauthorizedException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

  end
end
