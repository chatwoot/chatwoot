# frozen_string_literal: true

module Aws
  # @api private
  class TokenProviderChain
    def initialize(config = nil)
      @config = config
    end

    # @return [TokenProvider, nil]
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
        [:static_profile_sso_token, {}],
        [:sso_token, {}]
      ]
    end

    def static_profile_sso_token(options)
      if Aws.shared_config.config_enabled? && options[:config] && options[:config].profile
        Aws.shared_config.sso_token_from_config(
          profile: options[:config].profile
        )
      end
    end


    def sso_token(options)
      profile_name = determine_profile_name(options)
      if Aws.shared_config.config_enabled?
        Aws.shared_config.sso_token_from_config(profile: profile_name)
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def determine_profile_name(options)
      (options[:config] && options[:config].profile) || ENV['AWS_PROFILE'] || ENV['AWS_DEFAULT_PROFILE'] || 'default'
    end

  end
end
