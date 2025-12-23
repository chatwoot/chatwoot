# frozen_string_literal: true

module Aws
  # An auto-refreshing credential provider that assumes a role via
  # {Aws::SSO::Client#get_role_credentials} using a cached access
  # token. When `sso_session` is specified, token refresh logic from
  # {Aws::SSOTokenProvider} will be used to refresh the token if possible.
  # This class does NOT implement the SSO login token flow - tokens
  # must generated separately by running `aws login` from the
  # AWS CLI with the correct profile. The `SSOCredentials` will
  # auto-refresh the AWS credentials from SSO.
  #
  #     # You must first run aws sso login --profile your-sso-profile
  #     sso_credentials = Aws::SSOCredentials.new(
  #       sso_account_id: '123456789',
  #       sso_role_name: "role_name",
  #       sso_region: "us-east-1",
  #       sso_session: 'my_sso_session'
  #     )
  #     ec2 = Aws::EC2::Client.new(credentials: sso_credentials)
  #
  # If you omit `:client` option, a new {Aws::SSO::Client} object will be
  # constructed with additional options that were provided.
  #
  # @see Aws::SSO::Client#get_role_credentials
  # @see https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html
  class SSOCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @api private
    LEGACY_REQUIRED_OPTS =         [:sso_start_url, :sso_account_id, :sso_region, :sso_role_name].freeze
    TOKEN_PROVIDER_REQUIRED_OPTS = [:sso_session, :sso_account_id, :sso_region, :sso_role_name].freeze

    # @api private
    SSO_LOGIN_GUIDANCE = 'The SSO session associated with this profile has '\
    'expired or is otherwise invalid. To refresh this SSO session run '\
    'aws sso login with the corresponding profile.'.freeze

    # @option options [required, String] :sso_account_id The AWS account ID
    #   that temporary AWS credentials will be resolved for
    #
    # @option options [required, String] :sso_role_name The corresponding
    #   IAM role in the AWS account that temporary AWS credentials
    #   will be resolved for.
    #
    # @option options [required, String] :sso_region The AWS region where the
    #   SSO directory for the given sso_start_url is hosted.
    #
    # @option options [String] :sso_session The SSO Token used for fetching
    #   the token. If provided, refresh logic from the {Aws::SSOTokenProvider}
    #   will be used.
    #
    # @option options [String] :sso_start_url (legacy profiles) If provided,
    #   legacy token fetch behavior will be used, which does not support
    #   token refreshing.  The start URL is provided by the SSO
    #   service via the console and is the URL used to
    #   login to the SSO directory. This is also sometimes referred to as
    #   the "User Portal URL".
    #
    # @option options [SSO::Client] :client Optional `SSO::Client`.  If not
    #   provided, a client will be constructed.
    #
    # @option options [Callable] before_refresh Proc called before
    #   credentials are refreshed. `before_refresh` is called
    #   with an instance of this object when
    #   AWS credentials are required and need to be refreshed.
    def initialize(options = {})
      options = options.select {|k, v| !v.nil? }
      if (options[:sso_session])
        missing_keys = TOKEN_PROVIDER_REQUIRED_OPTS.select { |k| options[k].nil? }
        unless missing_keys.empty?
          raise ArgumentError, "Missing required keys: #{missing_keys}"
        end
        @legacy = false
        @sso_role_name = options.delete(:sso_role_name)
        @sso_account_id = options.delete(:sso_account_id)

        # if client has been passed, don't pass through to SSOTokenProvider
        @client = options.delete(:client)
        options.delete(:sso_start_url)
        @token_provider = Aws::SSOTokenProvider.new(options.dup)
        @sso_session = options.delete(:sso_session)
        @sso_region = options.delete(:sso_region)

        unless @client
          client_opts = {}
          options.each_pair { |k,v| client_opts[k] = v unless CLIENT_EXCLUDE_OPTIONS.include?(k) }
          client_opts[:region] = @sso_region
          client_opts[:credentials] = nil
          @client = Aws::SSO::Client.new(client_opts)
        end
      else # legacy behavior
        missing_keys = LEGACY_REQUIRED_OPTS.select { |k| options[k].nil? }
        unless missing_keys.empty?
          raise ArgumentError, "Missing required keys: #{missing_keys}"
        end
        @legacy = true
        @sso_start_url = options.delete(:sso_start_url)
        @sso_region = options.delete(:sso_region)
        @sso_role_name = options.delete(:sso_role_name)
        @sso_account_id = options.delete(:sso_account_id)

        # validate we can read the token file
        read_cached_token

        client_opts = {}
        options.each_pair { |k,v| client_opts[k] = v unless CLIENT_EXCLUDE_OPTIONS.include?(k) }
        client_opts[:region] = @sso_region
        client_opts[:credentials] = nil

        @client = options[:client] || Aws::SSO::Client.new(client_opts)
      end

      @async_refresh = true
      super
    end

    # @return [SSO::Client]
    attr_reader :client

    private

    def read_cached_token
      cached_token = Json.load(File.read(sso_cache_file))
      # validation
      unless cached_token['accessToken'] && cached_token['expiresAt']
        raise ArgumentError, 'Missing required field(s)'
      end
      expires_at = DateTime.parse(cached_token['expiresAt'])
      if expires_at < DateTime.now
        raise ArgumentError, 'Cached SSO Token is expired.'
      end
      cached_token
    rescue Errno::ENOENT, Aws::Json::ParseError, ArgumentError
      raise Errors::InvalidSSOCredentials, SSO_LOGIN_GUIDANCE
    end

    def refresh
      c = if @legacy
            cached_token = read_cached_token
            @client.get_role_credentials(
              account_id: @sso_account_id,
              role_name: @sso_role_name,
              access_token: cached_token['accessToken']
            ).role_credentials
          else
            @client.get_role_credentials(
              account_id: @sso_account_id,
              role_name: @sso_role_name,
              access_token: @token_provider.token.token
            ).role_credentials
          end

      @credentials = Credentials.new(
        c.access_key_id,
        c.secret_access_key,
        c.session_token
      )
      @expiration = Time.at(c.expiration / 1000.0)
    end

    def sso_cache_file
      start_url_sha1 = OpenSSL::Digest::SHA1.hexdigest(@sso_start_url.encode('utf-8'))
      File.join(Dir.home, '.aws', 'sso', 'cache', "#{start_url_sha1}.json")
    rescue ArgumentError
      # Dir.home raises ArgumentError when ENV['home'] is not set
      raise ArgumentError, "Unable to load sso_cache_file: ENV['HOME'] is not set."
    end
  end
end
