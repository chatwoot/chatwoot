# frozen_string_literal: true

module Aws
  module Partitions
    class Partition
      # @option options [required, String] :name
      # @option options [required, Hash<String,Region>] :regions
      # @option options [required, Hash<String,Service>] :services
      # @api private
      def initialize(options = {})
        @name = options[:name]
        @regions = options[:regions]
        @region_regex = options[:region_regex]
        @services = options[:services]
        @metadata = options[:metadata]
      end

      # @return [String] The partition name, e.g. "aws", "aws-cn", "aws-us-gov".
      attr_reader :name

      # @return [String] The regex representing the region format.
      attr_reader :region_regex

      # @return [Metadata] The metadata for the partition.
      attr_reader :metadata

      # @param [String] region_name The name of the region, e.g. "us-east-1".
      # @return [Region]
      # @raise [ArgumentError] Raises `ArgumentError` for unknown region name.
      def region(region_name)
        if @regions.key?(region_name)
          @regions[region_name]
        else
          msg = "invalid region name #{region_name.inspect}; valid region "\
                "names include #{@regions.keys.join(', ')}"
          raise ArgumentError, msg
        end
      end

      # @return [Array<Region>]
      def regions
        @regions.values
      end

      # @param [String] region_name The name of the region, e.g. "us-east-1".
      # @return [Boolean] true if the region is in the partition.
      def region?(region_name)
        @regions.key?(region_name)
      end

      # @param [String] service_name The service module name.
      # @return [Service]
      # @raise [ArgumentError] Raises `ArgumentError` for unknown service name.
      def service(service_name)
        if @services.key?(service_name)
          @services[service_name]
        else
          msg = "invalid service name #{service_name.inspect}; valid service "\
                "names include #{@services.keys.join(', ')}"
          raise ArgumentError, msg
        end
      end

      # @return [Array<Service>]
      def services
        @services.values
      end

      # @param [String] service_name The service module name.
      # @return [Boolean] true if the service is in the partition.
      def service?(service_name)
        @services.key?(service_name)
      end

      class << self
        # @api private
        def build(partition)
          Partition.new(
            name: partition['partition'],
            regions: build_regions(partition),
            region_regex: partition['regionRegex'],
            services: build_services(partition)
          )
        end

        private

        # @param [Hash] partition
        # @return [Hash<String,Region>]
        def build_regions(partition)
          partition['regions'].each_with_object({}) do |(region_name, region), regions|
            next if region_name == "#{partition['partition']}-global"

            regions[region_name] = Region.build(
              region_name, region, partition
            )
          end
        end

        # @param [Hash] partition
        # @return [Hash<String,Service>]
        def build_services(partition)
          Partitions.service_ids.each_with_object({}) do
            |(service_name, service), services|
            service_data = partition['services'].fetch(
              service, 'endpoints' => {}
            )
            services[service_name] = Service.build(
              service_name, service_data, partition
            )
          end
        end
      end
    end
  end
end
