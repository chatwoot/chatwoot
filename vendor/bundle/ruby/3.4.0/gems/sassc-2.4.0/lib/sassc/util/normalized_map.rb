# frozen_string_literal: true

require "delegate"

# A hash that normalizes its string keys while still allowing you to get back
# to the original keys that were stored. If several different values normalize
# to the same value, whichever is stored last wins.

class SassC::Util::NormalizedMap

  # Create a normalized map
  def initialize(map = nil)
    @key_strings = {}
    @map = {}
    map.each {|key, value| self[key] = value} if map
  end

  # Specifies how to transform the key.
  # This can be overridden to create other normalization behaviors.
  def normalize(key)
    key.tr("-", "_")
  end

  # Returns the version of `key` as it was stored before
  # normalization. If `key` isn't in the map, returns it as it was
  # passed in.
  # @return [String]
  def denormalize(key)
    @key_strings[normalize(key)] || key
  end

  # @private
  def []=(k, v)
    normalized = normalize(k)
    @map[normalized] = v
    @key_strings[normalized] = k
    v
  end

  # @private
  def [](k)
    @map[normalize(k)]
  end

  # @private
  def has_key?(k)
    @map.has_key?(normalize(k))
  end

  # @private
  def delete(k)
    normalized = normalize(k)
    @key_strings.delete(normalized)
    @map.delete(normalized)
  end

  # @return [Hash] Hash with the keys as they were stored (before normalization).
  def as_stored
    SassC::Util.map_keys(@map) {|k| @key_strings[k]}
  end

  def empty?
    @map.empty?
  end

  def values
    @map.values
  end

  def keys
    @map.keys
  end

  def each
    @map.each {|k, v| yield(k, v)}
  end

  def size
    @map.size
  end

  def to_hash
    @map.dup
  end

  def to_a
    @map.to_a
  end

  def map
    @map.map {|k, v| yield(k, v)}
  end

  def dup
    d = super
    d.send(:instance_variable_set, "@map", @map.dup)
    d
  end

  def sort_by
    @map.sort_by {|k, v| yield k, v}
  end

  def update(map)
    map = map.as_stored if map.is_a?(NormalizedMap)
    map.each {|k, v| self[k] = v}
  end

  def method_missing(method, *args, &block)
    @map.send(method, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    @map.respond_to?(method, include_private)
  end

end
