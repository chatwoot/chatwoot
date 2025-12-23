# frozen_string_literal: true

module Aws
  # @api private
  class CredentialProviderChain
    def initialize(config = nil)
      @config = config
    end

    # @return [CredentialProvider, nil]
    def resolve
      providers.each do |method_name, options|
        provider = send(method_name, options.merge(config: @config))
        return provider if provider && provider.set?
      end
      nil
    end

    private

    def providers
      [
        [:static_credentials, {}],
        [:static_profile_assume_role_web_identity_credentials, {}],
        [:static_profile_sso_credentials, {}],
        [:static_profile_assume_role_credentials, {}],
        [:static_profile_credentials, {}],
        [:static_profile_process_credentials, {}],
        [:env_credentials, {}],
        [:assume_role_web_identity_credentials, {}],
        [:sso_credentials, {}],
        [:assume_role_credentials, {}],
        [:shared_credentials, {}],
        [:process_credentials, {}],
        [:instance_profile_credentials, {
          retries: @config ? @config.instance_profile_credentials_retries : 0,
          http_open_timeout: @config ? @config.instance_profile_credentials_timeout : 1,
          http_read_timeout: @config ? @config.instance_profile_credentials_timeout : 1
        }]
      ]
    end

    def static_credentials(options)
      if options[:config]
        Credentials.new(
          options[:config].access_key_id,
          options[:config].secret_access_key,
          options[:config].session_token
        )
      end
    end

    def static_profile_assume_role_web_identity_credentials(options)
      if Aws.shared_config.config_enabled? && options[:config] && options[:config].profile
        Aws.shared_config.assume_role_web_identity_credentials_from_config(
          profile: options[:config].profile,
          region: options[:config].region
        )
      end
    end

    def static_profile_sso_credentials(options)
      if Aws.shared_config.config_enabled? && options[:config] && options[:config].profile
        Aws.shared_config.sso_credentials_from_config(
          profile: options[:config].profile
        )
      end
    end

    def static_profile_assume_role_credentials(options)
      if Aws.shared_config.config_enabled? && options[:config] && options[:config].profile
        assume_role_with_profile(options, options[:config].profile)
      end
    end

    def static_profile_credentials(options)
      if options[:config] && options[:config].profile
        SharedCredentials.new(profile_name: options[:config].profile)
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def static_profile_process_credentials(options)
      if Aws.shared_config.config_enabled? && options[:config] && options[:config].profile
        process_provider = Aws.shared_config.credential_process(profile: options[:config].profile)
        ProcessCredentials.new(process_provider) if process_provider
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def env_credentials(_options)
      key =    %w[AWS_ACCESS_KEY_ID AMAZON_ACCESS_KEY_ID AWS_ACCESS_KEY]
      secret = %w[AWS_SECRET_ACCESS_KEY AMAZON_SECRET_ACCESS_KEY AWS_SECRET_KEY]
      token =  %w[AWS_SESSION_TOKEN AMAZON_SESSION_TOKEN]
      Credentials.new(envar(key), envar(secret), envar(token))
    end

    def envar(keys)
      keys.each do |key|
        return ENV[key] if ENV.key?(key)
      end
      nil
    end

    def determine_profile_name(options)
      (options[:config] && options[:config].profile) || ENV['AWS_PROFILE'] || ENV['AWS_DEFAULT_PROFILE'] || 'default'
    end

    def shared_credentials(options)
      profile_name = determine_profile_name(options)
      SharedCredentials.new(profile_name: profile_name)
    rescue Errors::NoSuchProfileError
      nil
    end

    def process_credentials(options)
      profile_name = determine_profile_name(options)
      if Aws.shared_config.config_enabled? &&
         (process_provider = Aws.shared_config.credential_process(profile: profile_name))
        ProcessCredentials.new(process_provider)
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def sso_credentials(options)
      profile_name = determine_profile_name(options)
      if Aws.shared_config.config_enabled?
        Aws.shared_config.sso_credentials_from_config(profile: profile_name)
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def assume_role_credentials(options)
      if Aws.shared_config.config_enabled?
        assume_role_with_profile(options, determine_profile_name(options))
      end
    end

    def assume_role_web_identity_credentials(options)
      region = options[:config].region if options[:config]
      if (role_arn = ENV['AWS_ROLE_ARN']) && (token_file = ENV['AWS_WEB_IDENTITY_TOKEN_FILE'])
        cfg = {
          role_arn: role_arn,
          web_identity_token_file: token_file,
          role_session_name: ENV['AWS_ROLE_SESSION_NAME']
        }
        cfg[:region] = region if region
        AssumeRoleWebIdentityCredentials.new(cfg)
      elsif Aws.shared_config.config_enabled?
        profile = options[:config].profile if options[:config]
        Aws.shared_config.assume_role_web_identity_credentials_from_config(
          profile: profile,
          region: region
        )
      end
    end

    def instance_profile_credentials(options)
      profile_name = determine_profile_name(options)
      if ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] ||
         ENV['AWS_CONTAINER_CREDENTIALS_FULL_URI']
        ECSCredentials.new(options)
      else
        InstanceProfileCredentials.new(options.merge(profile: profile_name))
      end
    end

    def assume_role_with_profile(options, profile_name)
      assume_opts = {
        profile: profile_name,
        chain_config: @config
      }
      if options[:config] && options[:config].region
        assume_opts[:region] = options[:config].region
      end
      Aws.shared_config.assume_role_credentials_from_config(assume_opts)
    end
  end
end
