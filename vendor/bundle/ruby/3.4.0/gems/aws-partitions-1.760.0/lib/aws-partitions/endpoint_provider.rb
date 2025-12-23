# frozen_string_literal: true

module Aws
  module Partitions
    # @api private
    class EndpointProvider
      # When sts_regional_endpoint is set to `legacy`, the endpoint
      # pattern stays global for the following regions:
      STS_LEGACY_REGIONS = %w[
        ap-northeast-1
        ap-south-1
        ap-southeast-1
        ap-southeast-2
        aws-global
        ca-central-1
        eu-central-1
        eu-north-1
        eu-west-1
        eu-west-2
        eu-west-3
        sa-east-1
        us-east-1
        us-east-2
        us-west-1
        us-west-2
      ].freeze

      # Intentionally marked private. The format of the endpoint rules
      # is an implementation detail.
      # @api private
      def initialize(rules)
        @rules = rules
      end

      # @param [String] region The region for the client.
      # @param [String] service The endpoint prefix for the service, e.g.
      #   "monitoring" for cloudwatch.
      # @param [String] sts_regional_endpoints [STS only] Whether to use
      #   `legacy` (global endpoint for legacy regions) or `regional` mode for
      #   using regional endpoint for supported regions except 'aws-global'
      # @param [Hash] variants Endpoint variants such as 'fips' or 'dualstack'
      # @option variants [Boolean] :dualstack When true, resolve a dualstack
      #   endpoint.
      # @option variants [Boolean] :fips When true, resolve a FIPS endpoint.
      # @api private Use the static class methods instead.
      def resolve(region, service, sts_regional_endpoints, variants)
        'https://' + endpoint_for(region, service, build_is_global_fn(sts_regional_endpoints), variants)
      end

      # @api private Use the static class methods instead.
      def signing_region(region, service, sts_regional_endpoints)
        credential_scope(region, service, build_is_global_fn(sts_regional_endpoints))
          .fetch('region', region)
      end

      # @api private Use the static class methods instead.
      def signing_service(region, service)
        # don't default to the service name
        # signers should prefer the api metadata's signingName
        # if no service is set in the credentialScope
        credential_scope(region, service, build_is_global_fn('regional'))
          .fetch('service', nil)
      end

      # @param [String] region The region used to fetch the partition.
      # @param [String] service Used only if dualstack is true. Used to find a
      #   DNS suffix for a specific service.
      # @param [Hash] variants Endpoint variants such as 'fips' or 'dualstack'
      # @option variants [Boolean] :dualstack When true, resolve a dualstack
      #   endpoint.
      # @option variants [Boolean] :fips When true, resolve a FIPS endpoint.
      # @api private Use the static class methods instead.
      def dns_suffix_for(region, service, variants)
        if configured_variants?(variants)
          resolve_variant(region, service, variants)['dnsSuffix']
        else
          get_partition(region)['dnsSuffix']
        end
      end

      private

      def configured_variants?(variants)
        variants.values.any?
      end

      def fetch_variant(cfg, tags)
        variants = cfg.fetch('variants', [])
        variants.find { |v| tags == Set.new(v['tags']) } || {}
      end

      def resolve_variant(region, service, config_variants)
        tags = Set.new(config_variants.select { |_k,v| v == true }.map { |k,_v| k.to_s })
        is_global_fn = build_is_global_fn # ignore legacy STS config for variants

        partition_cfg = get_partition(region)
        service_cfg = partition_cfg.fetch('services', {})
                                   .fetch(service, {})

        endpoints_cfg = service_cfg.fetch('endpoints', {})

        if is_global_fn.call(service, region, endpoints_cfg, service_cfg)
          region = service_cfg.fetch('partitionEndpoint', region)
        end

        region_cfg = endpoints_cfg.fetch(region, {})
        warn_deprecation(service, region) if region_cfg['deprecated']

        partition_defaults = fetch_variant(partition_cfg.fetch('defaults', {}), tags)
        service_defaults = fetch_variant(service_cfg.fetch('defaults', {}), tags)
        endpoint_cfg = fetch_variant(region_cfg, tags)

        # merge upwards, preferring values from endpoint > service > partition
        partition_defaults.merge(service_defaults.merge(endpoint_cfg))
      end

      def validate_variant!(config_variants, resolved_variant)
        unless resolved_variant['hostname'] && resolved_variant['dnsSuffix']
          enabled_variants = config_variants.select { |_k, v| v}.map { |k, _v| k.to_s }.join(', ')
            raise ArgumentError,
                "#{enabled_variants} not supported for this region and partition."
        end
      end

      def endpoint_for(region, service, is_global_fn, variants)
        if configured_variants?(variants)
          endpoint_with_variants_for(region, service, variants)
        else
          endpoint_no_variants_for(region, service, is_global_fn)
        end
      end

      def endpoint_with_variants_for(region, service, variants)
        variant = resolve_variant(region, service, variants)
        validate_variant!(variants, variant)
        variant['hostname'].sub('{region}', region)
                           .sub('{service}', service)
                           .sub('{dnsSuffix}', variant['dnsSuffix'])
      end

      def endpoint_no_variants_for(region, service, is_global_fn)
        partition = get_partition(region)
        service_cfg = partition.fetch('services', {}).fetch(service, {})

        # Find the default endpoint
        default_endpoint = service_cfg
                   .fetch('defaults', {})
                   .fetch('hostname', partition['defaults']['hostname'])

        endpoints = service_cfg.fetch('endpoints', {})

        # Check for global endpoint.
        if is_global_fn.call(service, region, endpoints, service_cfg)
          region = service_cfg.fetch('partitionEndpoint', region)
        end

        # Check for service/region level endpoint.
        region_cfg = endpoints
                   .fetch(region, {})
        endpoint = region_cfg
                   .fetch('hostname', default_endpoint)

        warn_deprecation(service, region) if region_cfg['deprecated']

        # Replace placeholders from the endpoints
        endpoint.sub('{region}', region)
                .sub('{service}', service)
                .sub('{dnsSuffix}', partition['dnsSuffix'])
      end

      def warn_deprecation(service, region)
        warn("The endpoint for service: #{service}, region: #{region}"\
             ' is deprecated.')
      end

      # returns a callable that takes a region
      # and returns true if the service is global
      def build_is_global_fn(sts_regional_endpoints='regional')
        lambda do |service, region, endpoints, service_cfg|
          # Check for sts legacy behavior
          sts_legacy = service == 'sts' &&
            sts_regional_endpoints == 'legacy' &&
            STS_LEGACY_REGIONS.include?(region)

          is_global = !endpoints.key?(region) &&
            service_cfg['isRegionalized'] == false

          sts_legacy || is_global
        end
      end

      def credential_scope(region, service, is_global_fn)
        partition = get_partition(region)
        service_cfg = partition.fetch('services', {})
                               .fetch(service, {})
        endpoints = service_cfg.fetch('endpoints', {})

        # Check for global endpoint.
        if is_global_fn.call(service, region, endpoints, service_cfg)
          region = service_cfg.fetch('partitionEndpoint', region)
        end

        default_credential_scope = service_cfg
                                     .fetch('defaults', {})
                                     .fetch('credentialScope', {})

        endpoints
          .fetch(region, {})
          .fetch('credentialScope', default_credential_scope)
      end

      def get_partition(region_or_partition)
        partition_containing_region(region_or_partition) ||
          partition_matching_region(region_or_partition) ||
          partition_matching_name(region_or_partition) ||
          default_partition
      end

      def partition_containing_region(region)
        @rules['partitions'].find do |p|
          p['regions'].key?(region)
        end
      end

      def partition_matching_region(region)
        @rules['partitions'].find do |p|
          p['regionRegex'] && region.match(p['regionRegex']) ||
            p['services'].values.find do |svc|
              svc['endpoints'].key?(region) if svc.key?('endpoints')
            end
        end
      end

      def partition_matching_name(partition_name)
        @rules['partitions'].find { |p| p['partition'] == partition_name }
      end

      def default_partition
        @rules['partitions'].find { |p| p['partition'] == 'aws' } ||
          @rules['partitions'].first
      end

      class << self
        def resolve(region, service, sts_endpoint = 'regional', variants = {})
          default_provider.resolve(region, service, sts_endpoint, variants)
        end

        def signing_region(region, service, sts_regional_endpoints = 'regional')
          default_provider.signing_region(region, service, sts_regional_endpoints)
        end

        def signing_service(region, service)
          default_provider.signing_service(region, service)
        end

        def dns_suffix_for(region, service = nil, variants = {})
          default_provider.dns_suffix_for(region, service, variants)
        end

        private

        def default_provider
          @default_provider ||= EndpointProvider.new(Partitions.defaults)
        end
      end
    end
  end
end
