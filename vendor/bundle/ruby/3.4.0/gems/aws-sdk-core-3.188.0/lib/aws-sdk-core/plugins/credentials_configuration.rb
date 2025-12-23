# frozen_string_literal: true

module Aws
  # @api private
  module Plugins
    # @api private
    class CredentialsConfiguration < Seahorse::Client::Plugin

      option(:access_key_id, doc_type: String, docstring: '')

      option(:secret_access_key, doc_type: String, docstring: '')

      option(:session_token, doc_type: String, docstring: '')

      option(:profile,
        doc_default: 'default',
        doc_type: String,
        docstring: <<-DOCS)
Used when loading credentials from the shared credentials file
at HOME/.aws/credentials.  When not specified, 'default' is used.
        DOCS

      option(:credentials,
        required: true,
        doc_type: 'Aws::CredentialProvider',
        docstring: <<-DOCS
Your AWS credentials. This can be an instance of any one of the
following classes:

* `Aws::Credentials` - Used for configuring static, non-refreshing
  credentials.

* `Aws::SharedCredentials` - Used for loading static credentials from a
  shared file, such as `~/.aws/config`.

* `Aws::AssumeRoleCredentials` - Used when you need to assume a role.

* `Aws::AssumeRoleWebIdentityCredentials` - Used when you need to
  assume a role after providing credentials via the web.

* `Aws::SSOCredentials` - Used for loading credentials from AWS SSO using an
  access token generated from `aws login`.

* `Aws::ProcessCredentials` - Used for loading credentials from a
  process that outputs to stdout.

* `Aws::InstanceProfileCredentials` - Used for loading credentials
  from an EC2 IMDS on an EC2 instance.

* `Aws::ECSCredentials` - Used for loading credentials from
  instances running in ECS.

* `Aws::CognitoIdentityCredentials` - Used for loading credentials
  from the Cognito Identity service.

When `:credentials` are not configured directly, the following
locations will be searched for credentials:

* `Aws.config[:credentials]`
* The `:access_key_id`, `:secret_access_key`, and `:session_token` options.
* ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
* `~/.aws/credentials`
* `~/.aws/config`
* EC2/ECS IMDS instance profile - When used by default, the timeouts
  are very aggressive. Construct and pass an instance of
  `Aws::InstanceProfileCredentails` or `Aws::ECSCredentials` to
  enable retries and extended timeouts. Instance profile credential
  fetching can be disabled by setting ENV['AWS_EC2_METADATA_DISABLED']
  to true.
        DOCS
      ) do |config|
        CredentialProviderChain.new(config).resolve
      end

      option(:instance_profile_credentials_retries, 0)

      option(:instance_profile_credentials_timeout, 1)

      option(:token_provider,
             required: false,
             doc_type: 'Aws::TokenProvider',
             docstring: <<-DOCS
A Bearer Token Provider. This can be an instance of any one of the
following classes:

* `Aws::StaticTokenProvider` - Used for configuring static, non-refreshing
  tokens.

* `Aws::SSOTokenProvider` - Used for loading tokens from AWS SSO using an
  access token generated from `aws login`.

When `:token_provider` is not configured directly, the `Aws::TokenProviderChain`
will be used to search for tokens configured for your profile in shared configuration files.
      DOCS
      ) do |config|
        if config.stub_responses
          StaticTokenProvider.new('token')
        else
          TokenProviderChain.new(config).resolve
        end
      end

    end
  end
end
