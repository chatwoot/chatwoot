# frozen_string_literal: true

class Redis
  module Commands
    module HyperLogLog
      # Add one or more members to a HyperLogLog structure.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Boolean] true if at least 1 HyperLogLog internal register was altered. false otherwise.
      def pfadd(key, member)
        send_command([:pfadd, key, member], &Boolify)
      end

      # Get the approximate cardinality of members added to HyperLogLog structure.
      #
      # If called with multiple keys, returns the approximate cardinality of the
      # union of the HyperLogLogs contained in the keys.
      #
      # @param [String, Array<String>] keys
      # @return [Integer]
      def pfcount(*keys)
        send_command([:pfcount] + keys.flatten(1))
      end

      # Merge multiple HyperLogLog values into an unique value that will approximate the cardinality of the union of
      # the observed Sets of the source HyperLogLog structures.
      #
      # @param [String] dest_key destination key
      # @param [String, Array<String>] source_key source key, or array of keys
      # @return [Boolean]
      def pfmerge(dest_key, *source_key)
        send_command([:pfmerge, dest_key, *source_key], &BoolifySet)
      end
    end
  end
end
