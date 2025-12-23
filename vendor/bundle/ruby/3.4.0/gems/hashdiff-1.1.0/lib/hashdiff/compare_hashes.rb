# frozen_string_literal: true

module Hashdiff
  # @private
  # Used to compare hashes
  class CompareHashes
    class << self
      def call(obj1, obj2, opts = {})
        return [] if obj1.empty? && obj2.empty?

        obj1_keys = obj1.keys
        obj2_keys = obj2.keys
        obj1_lookup = {}
        obj2_lookup = {}

        if opts[:indifferent]
          obj1_lookup = obj1_keys.each_with_object({}) { |k, h| h[k.to_s] = k }
          obj2_lookup = obj2_keys.each_with_object({}) { |k, h| h[k.to_s] = k }
          obj1_keys = obj1_keys.map { |k| k.is_a?(Symbol) ? k.to_s : k }
          obj2_keys = obj2_keys.map { |k| k.is_a?(Symbol) ? k.to_s : k }
        end

        added_keys = (obj2_keys - obj1_keys).sort_by(&:to_s)
        common_keys = (obj1_keys & obj2_keys).sort_by(&:to_s)
        deleted_keys = (obj1_keys - obj2_keys).sort_by(&:to_s)

        result = []

        opts[:ignore_keys].each { |k| common_keys.delete k }

        # add deleted properties
        deleted_keys.each do |k|
          k = opts[:indifferent] ? obj1_lookup[k] : k
          change_key = Hashdiff.prefix_append_key(opts[:prefix], k, opts)
          custom_result = Hashdiff.custom_compare(opts[:comparison], change_key, obj1[k], nil)

          if custom_result
            result.concat(custom_result)
          else
            result << ['-', change_key, obj1[k]]
          end
        end

        # recursive comparison for common keys
        common_keys.each do |k|
          prefix = Hashdiff.prefix_append_key(opts[:prefix], k, opts)

          k1 = opts[:indifferent] ? obj1_lookup[k] : k
          k2 = opts[:indifferent] ? obj2_lookup[k] : k
          result.concat(Hashdiff.diff(obj1[k1], obj2[k2], opts.merge(prefix: prefix)))
        end

        # added properties
        added_keys.each do |k|
          change_key = Hashdiff.prefix_append_key(opts[:prefix], k, opts)

          k = opts[:indifferent] ? obj2_lookup[k] : k
          custom_result = Hashdiff.custom_compare(opts[:comparison], change_key, nil, obj2[k])

          if custom_result
            result.concat(custom_result)
          else
            result << ['+', change_key, obj2[k]]
          end
        end

        result
      end
    end
  end
end
