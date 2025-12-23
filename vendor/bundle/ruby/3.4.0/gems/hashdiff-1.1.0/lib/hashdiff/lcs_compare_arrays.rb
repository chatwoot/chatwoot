# frozen_string_literal: true

module Hashdiff
  # @private
  # Used to compare arrays using the lcs algorithm
  class LcsCompareArrays
    class << self
      def call(obj1, obj2, opts = {})
        result = []

        changeset = Hashdiff.diff_array_lcs(obj1, obj2, opts) do |lcs|
          # use a's index for similarity
          lcs.each do |pair|
            prefix = Hashdiff.prefix_append_array_index(opts[:prefix], pair[0], opts)

            result.concat(Hashdiff.diff(obj1[pair[0]], obj2[pair[1]], opts.merge(prefix: prefix)))
          end
        end

        changeset.each do |change|
          next if change[0] != '-' && change[0] != '+'

          change_key = Hashdiff.prefix_append_array_index(opts[:prefix], change[1], opts)

          result << [change[0], change_key, change[2]]
        end

        result
      end
    end
  end
end
