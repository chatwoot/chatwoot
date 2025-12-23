# frozen_string_literal: true

require 'set'

module Aws
  # An auto-refreshing credential provider that assumes a role via
  # {Aws::STS::Client#assume_role}.
  #
  #     role_credentials = Aws::AssumeRoleCredentials.new(
  #       client: Aws::STS::Client.new(...),
  #       role_arn: "linked::account::arn",
  #       role_session_name: "session-name"
  #     )
  #     ec2 = Aws::EC2::Client.new(credentials: role_credentials)
  #
  # If you omit `:client` option, a new {Aws::STS::Client} object will be
  # constructed with additional options that were provided.
  #
  # @see Aws::STS::Client#assume_role
  class AssumeRoleCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @option options [required, String] :role_arn
    # @option options [required, String] :role_session_name
    # @option options [String] :policy
    # @option options [Integer] :duration_seconds
    # @option options [String] :external_id
    # @option options [STS::Client] :client
    # @option options [Callable] before_refresh Proc called before
    #   credentials are refreshed.  Useful for updating tokens.
    #   `before_refresh` is called when AWS credentials are
    #   required and need to be refreshed. Tokens can be refreshed using
    #   the following example:
    #
    #      before_refresh = Proc.new do |assume_role_credentials| do
    #        assume_role_credentials.assume_role_params['token_code'] = update_token
    #      end
    #
    def initialize(options = {})
      client_opts = {}
      @assume_role_params = {}
      options.each_pair do |key, value|
        if self.class.assume_role_options.include?(key)
          @assume_role_params[key] = value
        elsif !CLIENT_EXCLUDE_OPTIONS.include?(key)
          client_opts[key] = value
        end
      end
      @client = client_opts[:client] || STS::Client.new(client_opts)
      @async_refresh = true
      super
    end

    # @return [STS::Client]
    attr_reader :client

    # @return [Hash]
    attr_reader :assume_role_params

    private

    def refresh
      c = @client.assume_role(@assume_role_params).credentials
      @credentials = Credentials.new(
        c.access_key_id,
        c.secret_access_key,
        c.session_token
      )
      @expiration = c.expiration
    end

    class << self

      # @api private
      def assume_role_options
        @aro ||= begin
          input = STS::Client.api.operation(:assume_role).input
          Set.new(input.shape.member_names)
        end
      end

    end
  end
end
