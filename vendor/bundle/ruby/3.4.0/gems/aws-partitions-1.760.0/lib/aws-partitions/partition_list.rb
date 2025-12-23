# frozen_string_literal: true

module Aws
  module Partitions
    class PartitionList

      include Enumerable

      def initialize
        @partitions = {}
      end

      # @return [Enumerator<Partition>]
      def each(&block)
        @partitions.each_value(&block)
      end

      # @param [String] partition_name
      # @return [Partition]
      def partition(partition_name)
        if @partitions.key?(partition_name)
          @partitions[partition_name]
        else
          msg = "invalid partition name #{partition_name.inspect}; valid "\
                "partition names include %s" % [@partitions.keys.join(', ')]
          raise ArgumentError, msg
        end
      end

      # @return [Array<Partition>]
      def partitions
        @partitions.values
      end

      # @param [Partition] partition
      # @api private
      def add_partition(partition)
        if Partition === partition
          @partitions[partition.name] = partition
        else
          raise ArgumentError, "expected Partition, got #{partition.class}"
        end
      end

      # @param [Partition] partition
      # @api private
      def merge_metadata(partitions_metadata)
        partitions_metadata['partitions'].each do |partition_metadata|
          outputs = partition_metadata['outputs']

          if existing = @partitions[partition_metadata['id']]
            @partitions[partition_metadata['id']] = Partition.new(
              name: existing.name,
              regions: build_metadata_regions(
                partition_metadata['id'],
                partition_metadata['regions'],
                existing),
              region_regex: partition_metadata['regionRegex'],
              services: existing.services.each_with_object({}) do |s, services|
                services[s.name] = s
              end,
              metadata: outputs
            )
          else
            @partitions[partition_metadata['id']] = Partition.new(
              name: partition_metadata['id'],
              regions: build_metadata_regions(
                partition_metadata['id'], partition_metadata['regions']
              ),
              region_regex: partition_metadata['regionRegex'],
              services: {},
              metadata: outputs
            )
          end
        end
      end

      # Removed all partitions.
      # @api private
      def clear
        @partitions = {}
      end

      private

      def build_metadata_regions(partition_name, metadata_regions, existing = nil)
        metadata_regions.each_with_object({}) do |(region_name, region), regions|
          if existing && existing.region?(region_name)
            regions[region_name] = existing.region(region_name)
          else
            regions[region_name] = Region.new(
              name: region_name,
              description: region['description'],
              partition_name: partition_name,
              services: Set.new
            )
          end
        end
      end

      class << self

        # @api private
        def build(partitions)
          partitions['partitions'].inject(PartitionList.new) do |list, partition|
            list.add_partition(Partition.build(partition))
            list
          end
        end

      end
    end
  end
end
