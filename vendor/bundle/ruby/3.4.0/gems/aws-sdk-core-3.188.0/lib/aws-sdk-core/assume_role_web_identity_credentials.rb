# frozen_string_literal: true

require 'set'
require 'securerandom'
require 'base64'

module Aws
  # An auto-refreshing credential provider that assumes a role via
  # {Aws::STS::Client#assume_role_with_web_identity}.
  #
  #     role_credentials = Aws::AssumeRoleWebIdentityCredentials.new(
  #       client: Aws::STS::Client.new(...),
  #       role_arn: "linked::account::arn",
  #       web_identity_token_file: "/path/to/token/file",
  #       role_session_name: "session-name"
  #       ...
  #     )
  #     ec2 = Aws::EC2::Client.new(credentials: role_credentials)
  #
  # If you omit `:client` option, a new {Aws::STS::Client} object will be
  # constructed with additional options that were provided.
  #
  # @see Aws::STS::Client#assume_role_with_web_identity
  class AssumeRoleWebIdentityCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @param [Hash] options
    # @option options [required, String] :role_arn the IAM role
    #   to be assumed
    #
    # @option options [required, String] :web_identity_token_file
    #   absolute path to the file on disk containing OIDC token
    #
    # @option options [String] :role_session_name the IAM session
    #   name used to distinguish session, when not provided, base64
    #   encoded UUID is generated as the session name
    #
    # @option options [STS::Client] :client
    #
    # @option options [Callable] before_refresh Proc called before
    #   credentials are refreshed. `before_refresh` is called
    #   with an instance of this object when
    #   AWS credentials are required and need to be refreshed.
    def initialize(options = {})
      client_opts = {}
      @assume_role_web_identity_params = {}
      @token_file = options.delete(:web_identity_token_file)
      @async_refresh = true
      options.each_pair do |key, value|
        if self.class.assume_role_web_identity_options.include?(key)
          @assume_role_web_identity_params[key] = value
        elsif !CLIENT_EXCLUDE_OPTIONS.include?(key)
          client_opts[key] = value
        end
      end

      unless @assume_role_web_identity_params[:role_session_name]
        # not provided, generate encoded UUID as session name
        @assume_role_web_identity_params[:role_session_name] = _session_name
      end
      @client = client_opts[:client] || STS::Client.new(client_opts.merge(credentials: false))
      super
    end

    # @return [STS::Client]
    attr_reader :client

    private

    def refresh
      # read from token file everytime it refreshes
      @assume_role_web_identity_params[:web_identity_token] = _token_from_file(@token_file)

      c = @client.assume_role_with_web_identity(
        @assume_role_web_identity_params).credentials
      @credentials = Credentials.new(
        c.access_key_id,
        c.secret_access_key,
        c.session_token
      )
      @expiration = c.expiration
    end

    def _token_from_file(path)
      unless path && File.exist?(path)
        raise Aws::Errors::MissingWebIdentityTokenFile.new
      end
      File.read(path)
    end

    def _session_name
      Base64.strict_encode64(SecureRandom.uuid)
    end

    class << self

      # @api private
      def assume_role_web_identity_options
        @arwio ||= begin
          input = Aws::STS::Client.api.operation(:assume_role_with_web_identity).input
          Set.new(input.shape.member_names)
        end
      end
    end
  end
end
