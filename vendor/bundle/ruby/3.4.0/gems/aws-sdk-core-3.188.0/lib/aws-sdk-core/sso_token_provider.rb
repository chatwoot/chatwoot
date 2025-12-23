# frozen_string_literal: true

module Aws
  class SSOTokenProvider

    include TokenProvider
    include RefreshingToken

    # @api private
    SSO_REQUIRED_OPTS = [:sso_region, :sso_session].freeze

    # @api private
    SSO_LOGIN_GUIDANCE = 'The SSO session associated with this profile has '\
    'expired or is otherwise invalid. To refresh this SSO session run '\
    'aws sso login with the corresponding profile.'.freeze

    # @option options [required, String] :sso_region The AWS region where the
    #   SSO directory for the given sso_start_url is hosted.
    #
    # @option options [required, String] :sso_session The SSO Session used to
    #   for fetching this token.
    #
    # @option options [SSOOIDC::Client] :client Optional `SSOOIDC::Client`.  If not
    #   provided, a client will be constructed.
    #
    # @option options [Callable] before_refresh Proc called before
    #   credentials are refreshed. `before_refresh` is called
    #   with an instance of this object when
    #   AWS credentials are required and need to be refreshed.
    def initialize(options = {})

      missing_keys = SSO_REQUIRED_OPTS.select { |k| options[k].nil? }
      unless missing_keys.empty?
        raise ArgumentError, "Missing required keys: #{missing_keys}"
      end

      @sso_session = options.delete(:sso_session)
      @sso_region = options.delete(:sso_region)

      options[:region] = @sso_region
      options[:credentials] = nil
      options[:token_provider] = nil
      @client = options[:client] || Aws::SSOOIDC::Client.new(options)

      super
    end

    # @return [SSOOIDC::Client]
    attr_reader :client

    private

    def refresh
      # token is valid and not in refresh window - do not refresh it.
      return if @token && @token.expiration && !near_expiration?

      # token may not exist or is out of the expiration window
      # attempt to refresh from disk first (another process/application may have refreshed already)
      token_json = read_cached_token
      @token = Token.new(token_json['accessToken'], token_json['expiresAt'])
      return if @token && @token.expiration && !near_expiration?

      # The token is expired and needs to be refreshed
      if can_refresh_token?(token_json)
        begin
          current_time = Time.now
          resp = @client.create_token(
            grant_type: 'refresh_token',
            client_id: token_json['clientId'],
            client_secret: token_json['clientSecret'],
            refresh_token: token_json['refreshToken']
          )
          token_json['accessToken'] = resp.access_token
          token_json['expiresAt'] = current_time + resp.expires_in
          @token = Token.new(token_json['accessToken'], token_json['expiresAt'])

          if resp.refresh_token
            token_json['refreshToken'] = resp.refresh_token
          else
            token_json.delete('refreshToken')
          end

          update_token_cache(token_json)
        rescue
          # refresh has failed, continue attempting to use the token if its not hard expired
        end
      end

      if !@token.expiration || @token.expiration < Time.now
        # Token is hard expired, raise an exception
        raise Errors::InvalidSSOToken, 'Token is invalid and failed to refresh.'
      end
    end

    def read_cached_token
      cached_token = Json.load(File.read(sso_cache_file))
      # validation
      unless cached_token['accessToken'] && cached_token['expiresAt']
        raise ArgumentError, 'Missing required field(s)'
      end
      cached_token['expiresAt'] = Time.parse(cached_token['expiresAt'])
      cached_token
    rescue Errno::ENOENT, Aws::Json::ParseError, ArgumentError
      raise Errors::InvalidSSOToken, SSO_LOGIN_GUIDANCE
    end

    def update_token_cache(token_json)
      cached_token = token_json.dup
      cached_token['expiresAt'] = cached_token['expiresAt'].iso8601
      File.write(sso_cache_file, Json.dump(cached_token))
    end

    def sso_cache_file
      sso_session_sha1 = OpenSSL::Digest::SHA1.hexdigest(@sso_session.encode('utf-8'))
      File.join(Dir.home, '.aws', 'sso', 'cache', "#{sso_session_sha1}.json")
    rescue ArgumentError
      # Dir.home raises ArgumentError when ENV['home'] is not set
      raise ArgumentError, "Unable to load sso_cache_file: ENV['HOME'] is not set."
    end

    # return true if all required fields are present
    # return false if registrationExpiresAt exists and is later than now
    def can_refresh_token?(token_json)
      if token_json['clientId'] &&
        token_json['clientSecret'] &&
        token_json['refreshToken']

        return !token_json['registrationExpiresAt'] ||
          Time.parse(token_json['registrationExpiresAt']) > Time.now
      else
        false
      end
    end
  end
end
