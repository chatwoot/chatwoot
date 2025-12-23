require 'set'

module Sass
  module Util
    # A map from sets to values.
    # A value is \{#\[]= set} by providing a set (the "set-set") and a value,
    # which is then recorded as corresponding to that set.
    # Values are \{#\[] accessed} by providing a set (the "get-set")
    # and returning all values that correspond to set-sets
    # that are subsets of the get-set.
    #
    # SubsetMap preserves the order of values as they're inserted.
    #
    # @example
    #   ssm = SubsetMap.new
    #   ssm[Set[1, 2]] = "Foo"
    #   ssm[Set[2, 3]] = "Bar"
    #   ssm[Set[1, 2, 3]] = "Baz"
    #
    #   ssm[Set[1, 2, 3]] #=> ["Foo", "Bar", "Baz"]
    class SubsetMap
      # Creates a new, empty SubsetMap.
      def initialize
        @hash = {}
        @vals = []
      end

      # Whether or not this SubsetMap has any key-value pairs.
      #
      # @return [Boolean]
      def empty?
        @hash.empty?
      end

      # Associates a value with a set.
      # When `set` or any of its supersets is accessed,
      # `value` will be among the values returned.
      #
      # Note that if the same `set` is passed to this method multiple times,
      # all given `value`s will be associated with that `set`.
      #
      # This runs in `O(n)` time, where `n` is the size of `set`.
      #
      # @param set [#to_set] The set to use as the map key. May not be empty.
      # @param value [Object] The value to associate with `set`.
      # @raise [ArgumentError] If `set` is empty.
      def []=(set, value)
        raise ArgumentError.new("SubsetMap keys may not be empty.") if set.empty?

        index = @vals.size
        @vals << value
        set.each do |k|
          @hash[k] ||= []
          @hash[k] << [set, set.to_set, index]
        end
      end

      # Returns all values associated with subsets of `set`.
      #
      # In the worst case, this runs in `O(m*max(n, log m))` time,
      # where `n` is the size of `set`
      # and `m` is the number of associations in the map.
      # However, unless many keys in the map overlap with `set`,
      # `m` will typically be much smaller.
      #
      # @param set [Set] The set to use as the map key.
      # @return [Array<(Object, #to_set)>] An array of pairs,
      #   where the first value is the value associated with a subset of `set`,
      #   and the second value is that subset of `set`
      #   (or whatever `#to_set` object was used to set the value)
      #   This array is in insertion order.
      # @see #[]
      def get(set)
        res = set.map do |k|
          subsets = @hash[k]
          next unless subsets
          subsets.map do |subenum, subset, index|
            next unless subset.subset?(set)
            [index, subenum]
          end
        end.flatten(1)
        res.compact!
        res.uniq!
        res.sort!
        res.map! {|i, s| [@vals[i], s]}
        res
      end

      # Same as \{#get}, but doesn't return the subsets of the argument
      # for which values were found.
      #
      # @param set [Set] The set to use as the map key.
      # @return [Array] The array of all values
      #   associated with subsets of `set`, in insertion order.
      # @see #get
      def [](set)
        get(set).map {|v, _| v}
      end

      # Iterates over each value in the subset map. Ignores keys completely. If
      # multiple keys have the same value, this will return them multiple times.
      #
      # @yield [Object] Each value in the map.
      def each_value
        @vals.each {|v| yield v}
      end
    end
  end
end
