# frozen_string_literal: true

module Aws
  module S3
    module Plugins

      class IADRegionalEndpoint < Seahorse::Client::Plugin

        option(:s3_us_east_1_regional_endpoint,
          default: 'legacy',
          doc_type: String,
          docstring: <<-DOCS) do |cfg|
Pass in `regional` to enable the `us-east-1` regional endpoint.
Defaults to `legacy` mode which uses the global endpoint.
          DOCS
          resolve_iad_regional_endpoint(cfg)
        end

        private

        def self.resolve_iad_regional_endpoint(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:s3_us_east_1_regional_endpoint)
            end

          mode = ENV['AWS_S3_US_EAST_1_REGIONAL_ENDPOINT'] ||
            Aws.shared_config.s3_us_east_1_regional_endpoint(profile: cfg.profile) ||
            default_mode_value ||
            'legacy'
          mode = mode.downcase
          unless %w(legacy regional).include?(mode)
            raise ArgumentError, "expected :s3_us_east_1_regional_endpoint or"\
              " ENV['AWS_S3_US_EAST_1_REGIONAL_ENDPOINT'] to be `legacy` or"\
              " `regional`."
          end
          mode
        end

      end

    end
  end
end
