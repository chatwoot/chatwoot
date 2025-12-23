# frozen_string_literal: true

module Geocoder
  module Util
    #
    # Recursive version of Hash#merge!
    #
    # Adds the contents of +h2+ to +h1+,
    # merging entries in +h1+ with duplicate keys with those from +h2+.
    #
    # Compared with Hash#merge!, this method supports nested hashes.
    # When both +h1+ and +h2+ contains an entry with the same key,
    # it merges and returns the values from both hashes.
    #
    #    h1 = {"a" => 100, "b" => 200, "c" => {"c1" => 12, "c2" => 14}}
    #    h2 = {"b" => 254, "c" => {"c1" => 16, "c3" => 94}}
    #    recursive_hash_merge(h1, h2)   #=> {"a" => 100, "b" => 254, "c" => {"c1" => 16, "c2" => 14, "c3" => 94}}
    #
    # Simply using Hash#merge! would return
    #
    #    h1.merge!(h2)    #=> {"a" => 100, "b" = >254, "c" => {"c1" => 16, "c3" => 94}}
    #
    def self.recursive_hash_merge(h1, h2)
      h1.merge!(h2) do |_key, oldval, newval|
        oldval.class == h1.class ? self.recursive_hash_merge(oldval, newval) : newval
      end
    end
  end
end
