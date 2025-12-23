# frozen_string_literal: true

module Aws
  # @api private
  class SharedConfig
    SSO_CREDENTIAL_PROFILE_KEYS = %w[sso_account_id sso_role_name].freeze
    SSO_PROFILE_KEYS = %w[sso_session sso_start_url sso_region sso_account_id sso_role_name].freeze
    SSO_TOKEN_PROFILE_KEYS = %w[sso_session].freeze
    SSO_SESSION_KEYS = %w[sso_region sso_start_url].freeze


    # @return [String]
    attr_reader :credentials_path

    # @return [String]
    attr_reader :config_path

    # @return [String]
    attr_reader :profile_name

    # Constructs a new SharedConfig provider object. This will load the shared
    # credentials file, and optionally the shared configuration file, as ini
    # files which support profiles.
    #
    # By default, the shared credential file (the default path for which is
    # `~/.aws/credentials`) and the shared config file (the default path for
    # which is `~/.aws/config`) are loaded. However, if you set the
    # `ENV['AWS_SDK_CONFIG_OPT_OUT']` environment variable, only the shared
    # credential file will be loaded. You can specify the shared credential
    # file path with the `ENV['AWS_SHARED_CREDENTIALS_FILE']` environment
    # variable or with the `:credentials_path` option. Similarly, you can
    # specify the shared config file path with the `ENV['AWS_CONFIG_FILE']`
    # environment variable or with the `:config_path` option.
    #
    # The default profile name is 'default'. You can specify the profile name
    # with the `ENV['AWS_PROFILE']` environment variable or with the
    # `:profile_name` option.
    #
    # @param [Hash] options
    # @option options [String] :credentials_path Path to the shared credentials
    #   file. If not specified, will check `ENV['AWS_SHARED_CREDENTIALS_FILE']`
    #   before using the default value of "#{Dir.home}/.aws/credentials".
    # @option options [String] :config_path Path to the shared config file.
    #   If not specified, will check `ENV['AWS_CONFIG_FILE']` before using the
    #   default value of "#{Dir.home}/.aws/config".
    # @option options [String] :profile_name The credential/config profile name
    #   to use. If not specified, will check `ENV['AWS_PROFILE']` before using
    #   the fixed default value of 'default'.
    # @option options [Boolean] :config_enabled If true, loads the shared config
    #   file and enables new config values outside of the old shared credential
    #   spec.
    def initialize(options = {})
      @parsed_config = nil
      @profile_name = determine_profile(options)
      @config_enabled = options[:config_enabled]
      @credentials_path = options[:credentials_path] ||
                          determine_credentials_path
      @credentials_path = File.expand_path(@credentials_path) if @credentials_path
      @parsed_credentials = {}
      load_credentials_file if loadable?(@credentials_path)
      if @config_enabled
        @config_path = options[:config_path] || determine_config_path
        @config_path = File.expand_path(@config_path) if @config_path
        load_config_file if loadable?(@config_path)
      end
    end

    # @api private
    def fresh(options = {})
      @profile_name = nil
      @credentials_path = nil
      @config_path = nil
      @parsed_credentials = {}
      @parsed_config = nil
      @config_enabled = options[:config_enabled] ? true : false
      @profile_name = determine_profile(options)
      @credentials_path = options[:credentials_path] ||
                          determine_credentials_path
      load_credentials_file if loadable?(@credentials_path)
      if @config_enabled
        @config_path = options[:config_path] || determine_config_path
        load_config_file if loadable?(@config_path)
      end
    end

    # @return [Boolean] Returns `true` if a credential file
    #   exists and has appropriate read permissions at {#path}.
    # @note This method does not indicate if the file found at {#path}
    #   will be parsable, only if it can be read.
    def loadable?(path)
      !path.nil? && File.exist?(path) && File.readable?(path)
    end

    # @return [Boolean] returns `true` if use of the shared config file is
    #   enabled.
    def config_enabled?
      @config_enabled ? true : false
    end

    # Sources static credentials from shared credential/config files.
    #
    # @param [Hash] opts
    # @option options [String] :profile the name of the configuration file from
    #   which credentials are being sourced.
    # @return [Aws::Credentials] credentials sourced from configuration values,
    #   or `nil` if no valid credentials were found.
    def credentials(opts = {})
      p = opts[:profile] || @profile_name
      validate_profile_exists(p)
      if (credentials = credentials_from_shared(p, opts))
        credentials
      elsif (credentials = credentials_from_config(p, opts))
        credentials
      end
    end

    # Attempts to assume a role from shared config or shared credentials file.
    # Will always attempt first to assume a role from the shared credentials
    # file, if present.
    def assume_role_credentials_from_config(opts = {})
      p = opts.delete(:profile) || @profile_name
      chain_config = opts.delete(:chain_config)
      credentials = assume_role_from_profile(@parsed_credentials, p, opts, chain_config)
      if @parsed_config
        credentials ||= assume_role_from_profile(@parsed_config, p, opts, chain_config)
      end
      credentials
    end

    def assume_role_web_identity_credentials_from_config(opts = {})
      p = opts[:profile] || @profile_name
      if @config_enabled && @parsed_config
        entry = @parsed_config.fetch(p, {})
        if entry['web_identity_token_file'] && entry['role_arn']
          cfg = {
            role_arn: entry['role_arn'],
            web_identity_token_file: entry['web_identity_token_file'],
            role_session_name: entry['role_session_name']
          }
          cfg[:region] = opts[:region] if opts[:region]
          AssumeRoleWebIdentityCredentials.new(cfg)
        end
      end
    end

    # Attempts to load from shared config or shared credentials file.
    # Will always attempt first to load from the shared credentials
    # file, if present.
    def sso_credentials_from_config(opts = {})
      p = opts[:profile] || @profile_name
      credentials = sso_credentials_from_profile(@parsed_credentials, p)
      if @parsed_config
        credentials ||= sso_credentials_from_profile(@parsed_config, p)
      end
      credentials
    end

    # Attempts to load from shared config or shared credentials file.
    # Will always attempt first to load from the shared credentials
    # file, if present.
    def sso_token_from_config(opts = {})
      p = opts[:profile] || @profile_name
      token = sso_token_from_profile(@parsed_credentials, p)
      if @parsed_config
        token ||= sso_token_from_profile(@parsed_config, p)
      end
      token
    end

    # Source a custom configured endpoint from the shared configuration file
    #
    # @param [Hash] opts
    # @option opts [String] :profile
    # @option opts [String] :service_id
    def configured_endpoint(opts = {})
      # services section is only allowed in the shared config file (not credentials)
      profile = opts[:profile] || @profile_name
      service_id = opts[:service_id]&.gsub(" ", "_")&.downcase
      if @parsed_config && (prof_config = @parsed_config[profile])
        services_section_name = prof_config['services']
        if (services_config = @parsed_config["services #{services_section_name}"]) &&
          (service_config = services_config[service_id])
          return service_config['endpoint_url'] if service_config['endpoint_url']
        end
        return prof_config['endpoint_url']
      end
      nil
    end

    # Add an accessor method (similar to attr_reader) to return a configuration value
    # Uses the get_config_value below to control where
    # values are loaded from
    def self.config_reader(*attrs)
      attrs.each do |attr|
        define_method(attr) { |opts = {}| get_config_value(attr.to_s, opts) }
      end
    end

    config_reader(
      :region,
      :ca_bundle,
      :credential_process,
      :endpoint_discovery_enabled,
      :use_dualstack_endpoint,
      :use_fips_endpoint,
      :ec2_metadata_service_endpoint,
      :ec2_metadata_service_endpoint_mode,
      :ec2_metadata_v1_disabled,
      :max_attempts,
      :retry_mode,
      :adaptive_retry_wait_to_fill,
      :correct_clock_skew,
      :csm_client_id,
      :csm_enabled,
      :csm_host,
      :csm_port,
      :sts_regional_endpoints,
      :s3_use_arn_region,
      :s3_us_east_1_regional_endpoint,
      :s3_disable_multiregion_access_points,
      :defaults_mode,
      :sdk_ua_app_id,
      :disable_request_compression,
      :request_min_compression_size_bytes,
      :ignore_configured_endpoint_urls
    )

    private

    # Get a config value from from shared credential/config files.
    # Only loads a value when config_enabled is true
    # Return a value from credentials preferentially over config
    def get_config_value(key, opts)
      p = opts[:profile] || @profile_name

      value = @parsed_credentials.fetch(p, {})[key] if @parsed_credentials
      value ||= @parsed_config.fetch(p, {})[key] if @config_enabled && @parsed_config
      value
    end

    def assume_role_from_profile(cfg, profile, opts, chain_config)
      if cfg && prof_cfg = cfg[profile]
        opts[:source_profile] ||= prof_cfg['source_profile']
        credential_source = opts.delete(:credential_source)
        credential_source ||= prof_cfg['credential_source']
        if opts[:source_profile] && credential_source
          raise Errors::CredentialSourceConflictError,
            "Profile #{profile} has a source_profile, and "\
            'a credential_source. For assume role credentials, must '\
            'provide only source_profile or credential_source, not both.'
        elsif opts[:source_profile]
          opts[:visited_profiles] ||= Set.new
          opts[:credentials] = resolve_source_profile(opts[:source_profile], opts)
          if opts[:credentials]
            opts[:role_session_name] ||= prof_cfg['role_session_name']
            opts[:role_session_name] ||= 'default_session'
            opts[:role_arn] ||= prof_cfg['role_arn']
            opts[:duration_seconds] ||= prof_cfg['duration_seconds']
            opts[:external_id] ||= prof_cfg['external_id']
            opts[:serial_number] ||= prof_cfg['mfa_serial']
            opts[:profile] = opts.delete(:source_profile)
            opts.delete(:visited_profiles)
            AssumeRoleCredentials.new(opts)
          else
            raise Errors::NoSourceProfileError,
              "Profile #{profile} has a role_arn, and source_profile, but the"\
              ' source_profile does not have credentials.'
          end
        elsif credential_source
          opts[:credentials] = credentials_from_source(
            credential_source,
            chain_config
          )
          if opts[:credentials]
            opts[:role_session_name] ||= prof_cfg['role_session_name']
            opts[:role_session_name] ||= 'default_session'
            opts[:role_arn] ||= prof_cfg['role_arn']
            opts[:duration_seconds] ||= prof_cfg['duration_seconds']
            opts[:external_id] ||= prof_cfg['external_id']
            opts[:serial_number] ||= prof_cfg['mfa_serial']
            opts.delete(:source_profile) # Cleanup
            AssumeRoleCredentials.new(opts)
          else
            raise Errors::NoSourceCredentials,
              "Profile #{profile} could not get source credentials from"\
              " provider #{credential_source}"
          end
        elsif prof_cfg['role_arn']
          raise Errors::NoSourceProfileError, "Profile #{profile} has a role_arn, but no source_profile."
        end
      end
    end

    def resolve_source_profile(profile, opts = {})
      if opts[:visited_profiles] && opts[:visited_profiles].include?(profile)
        raise Errors::SourceProfileCircularReferenceError
      end
      opts[:visited_profiles].add(profile) if opts[:visited_profiles]

      profile_config = @parsed_credentials[profile]
      if @config_enabled
        profile_config ||= @parsed_config[profile]
      end

      if (creds = credentials(profile: profile))
        creds # static credentials
      elsif profile_config && profile_config['source_profile']
        opts.delete(:source_profile)
        assume_role_credentials_from_config(opts.merge(profile: profile))
      elsif (provider = assume_role_web_identity_credentials_from_config(opts.merge(profile: profile)))
        provider.credentials if provider.credentials.set?
      elsif (provider = assume_role_process_credentials_from_config(profile))
        provider.credentials if provider.credentials.set?
      elsif (provider = sso_credentials_from_config(profile: profile))
        provider.credentials if provider.credentials.set?
      end
    end

    def credentials_from_source(credential_source, config)
      case credential_source
      when 'Ec2InstanceMetadata'
        InstanceProfileCredentials.new(
          retries: config ? config.instance_profile_credentials_retries : 0,
          http_open_timeout: config ? config.instance_profile_credentials_timeout : 1,
          http_read_timeout: config ? config.instance_profile_credentials_timeout : 1
        )
      when 'EcsContainer'
        ECSCredentials.new
      else
        raise Errors::InvalidCredentialSourceError, "Unsupported credential_source: #{credential_source}"
      end
    end

    def assume_role_process_credentials_from_config(profile)
      validate_profile_exists(profile)
      credential_process = @parsed_credentials.fetch(profile, {})['credential_process']
      if @parsed_config
        credential_process ||= @parsed_config.fetch(profile, {})['credential_process']
      end
      ProcessCredentials.new(credential_process) if credential_process
    end

    def credentials_from_shared(profile, _opts)
      if @parsed_credentials && prof_config = @parsed_credentials[profile]
        credentials_from_profile(prof_config)
      end
    end

    def credentials_from_config(profile, _opts)
      if @parsed_config && prof_config = @parsed_config[profile]
        credentials_from_profile(prof_config)
      end
    end

    # If any of the sso_ profile values are present, attempt to construct
    # SSOCredentials
    def sso_credentials_from_profile(cfg, profile)
      if @parsed_config &&
         (prof_config = cfg[profile]) &&
         !(prof_config.keys & SSO_CREDENTIAL_PROFILE_KEYS).empty?

        if sso_session_name = prof_config['sso_session']
          sso_session = sso_session(cfg, profile, sso_session_name)

          sso_region = sso_session['sso_region']
          sso_start_url = sso_session['sso_start_url']

          # validate sso_region and sso_start_url don't conflict if set on profile and session
          if prof_config['sso_region'] &&  prof_config['sso_region'] != sso_region
            raise ArgumentError,
                  "sso-session #{sso_session_name}'s sso_region (#{sso_region}) " \
                    "does not match the profile #{profile}'s sso_region (#{prof_config['sso_region']}'"
          end
          if prof_config['sso_start_url'] &&  prof_config['sso_start_url'] != sso_start_url
            raise ArgumentError,
                  "sso-session #{sso_session_name}'s sso_start_url (#{sso_start_url}) " \
                    "does not match the profile #{profile}'s sso_start_url (#{prof_config['sso_start_url']}'"
          end
        else
          sso_region = prof_config['sso_region']
          sso_start_url = prof_config['sso_start_url']
        end

        SSOCredentials.new(
          sso_account_id: prof_config['sso_account_id'],
          sso_role_name: prof_config['sso_role_name'],
          sso_session: prof_config['sso_session'],
          sso_region: sso_region,
          sso_start_url: sso_start_url
          )
      end
    end

    # If the required sso_ profile values are present, attempt to construct
    # SSOTokenProvider
    def sso_token_from_profile(cfg, profile)
      if @parsed_config &&
        (prof_config = cfg[profile]) &&
        !(prof_config.keys & SSO_TOKEN_PROFILE_KEYS).empty?

        sso_session_name = prof_config['sso_session']
        sso_session = sso_session(cfg, profile, sso_session_name)

        SSOTokenProvider.new(
          sso_session: sso_session_name,
          sso_region: sso_session['sso_region']
        )
      end
    end

    def credentials_from_profile(prof_config)
      creds = Credentials.new(
        prof_config['aws_access_key_id'],
        prof_config['aws_secret_access_key'],
        prof_config['aws_session_token']
      )
      creds if creds.set?
    end

    def load_credentials_file
      @parsed_credentials = IniParser.ini_parse(
        File.read(@credentials_path)
      )
    end

    def load_config_file
      @parsed_config = IniParser.ini_parse(File.read(@config_path))
    end

    def determine_credentials_path
      ENV['AWS_SHARED_CREDENTIALS_FILE'] || default_shared_config_path('credentials')
    end

    def determine_config_path
      ENV['AWS_CONFIG_FILE'] || default_shared_config_path('config')
    end

    def default_shared_config_path(file)
      File.join(Dir.home, '.aws', file)
    rescue ArgumentError
      # Dir.home raises ArgumentError when ENV['home'] is not set
      nil
    end

    def validate_profile_exists(profile)
      unless (@parsed_credentials && @parsed_credentials[profile]) ||
             (@parsed_config && @parsed_config[profile])
        msg = "Profile `#{profile}' not found in #{@credentials_path}"\
              "#{" or #{@config_path}" if @config_path}"
        raise Errors::NoSuchProfileError, msg
      end
    end

    def determine_profile(options)
      ret = options[:profile_name]
      ret ||= ENV['AWS_PROFILE']
      ret ||= 'default'
      ret
    end

    def sso_session(cfg, profile, sso_session_name)
      # aws sso-configure may add quotes around sso session names with whitespace
      sso_session = cfg["sso-session #{sso_session_name}"] || cfg["sso-session '#{sso_session_name}'"]

      unless sso_session
        raise ArgumentError,
          "sso-session #{sso_session_name} must be defined in the config file. " \
                    "Referenced by profile #{profile}"
      end

      unless sso_session['sso_region']
        raise ArgumentError, "sso-session #{sso_session_name} missing required parameter: sso_region"
      end

      sso_session
    end
  end
end
