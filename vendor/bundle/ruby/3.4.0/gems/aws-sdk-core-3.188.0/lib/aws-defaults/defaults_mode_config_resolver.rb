# frozen_string_literal: true

module Aws
  #@api private
  class DefaultsModeConfigResolver

    @@application_region = nil
    @@application_region_mutex = Mutex.new
    @@imds_client = EC2Metadata.new(retries: 0, http_open_timeout: 0.01)

    # mappings from Ruby SDK configuration names to the
    # sdk defaults option names and (optional) scale modifiers
    CFG_OPTIONS = {
      retry_mode: { name: "retryMode" },
      sts_regional_endpoints: { name: "stsRegionalEndpoints" },
      s3_us_east_1_regional_endpoint: { name: "s3UsEast1RegionalEndpoints" },
      http_open_timeout: { name: "connectTimeoutInMillis", scale: 0.001 },
      http_read_timeout: { name: "timeToFirstByteTimeoutInMillis", scale: 0.001 },
      ssl_timeout: { name: "tlsNegotiationTimeoutInMillis", scale: 0.001 }
    }.freeze

    def initialize(sdk_defaults, cfg)
      @sdk_defaults = sdk_defaults
      @cfg = cfg
      @resolved_mode = nil
      @mutex = Mutex.new
    end

    # option_name should be the symbolized ruby name to resolve
    # returns the ruby appropriate value or nil if none are resolved
    def resolve(option_name)
      return unless (std_option = CFG_OPTIONS[option_name])
      mode = resolved_mode.downcase

      return nil if mode == 'legacy'

      value = resolve_for_mode(std_option[:name], mode)
      value = value * std_option[:scale] if value && std_option[:scale]

      value
    end

    private
    def resolved_mode
      @mutex.synchronize do
        return @resolved_mode unless @resolved_mode.nil?

        @resolved_mode = @cfg.defaults_mode == 'auto' ? resolve_auto_mode : @cfg.defaults_mode
      end
    end

    def resolve_auto_mode
      return "mobile" if env_mobile?

      region = application_current_region

      if region
        @cfg.region == region ? "in-region": "cross-region"
      else
        # We don't seem to be mobile, and we couldn't determine whether we're running within an AWS region. Fall back to standard.
        'standard'
      end
    end

    def application_current_region
      resolved_region = @@application_region_mutex.synchronize do
        return @@application_region unless @@application_region.nil?

        region = nil
        if ENV['AWS_EXECUTION_ENV']
          region = ENV['AWS_REGION'] || ENV['AWS_DEFAULT_REGION']
        end

        if region.nil? && ENV['AWS_EC2_METADATA_DISABLED']&.downcase != "true"
          begin
            region = @@imds_client.get('/latest/meta-data/placement/region')
          rescue
            # unable to get region, leave it unset
          end
        end

        # required so that we cache the unknown/nil result
        @@application_region = region || :unknown
      end
      resolved_region == :unknown ? nil : resolved_region
    end

    def resolve_for_mode(name, mode)
      base_value = @sdk_defaults['base'][name]
      mode_value = @sdk_defaults['modes'].fetch(mode, {})[name]

      if mode_value.nil?
        return base_value
      end

      return mode_value['override'] unless mode_value['override'].nil?
      return base_value + mode_value['add'] unless mode_value['add'].nil?
      return base_value * mode_value['multiply'] unless mode_value['multiply'].nil?
      return base_value
    end

    def env_mobile?
      false
    end

  end
end