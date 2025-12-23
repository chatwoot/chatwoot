require 'hashie/hash'
require 'hashie/array'
require 'hashie/utils'
require 'hashie/logger'
require 'hashie/extensions/key_conflict_warning'

module Hashie
  # Mash allows you to create pseudo-objects that have method-like
  # accessors for hash keys. This is useful for such implementations
  # as an API-accessing library that wants to fake robust objects
  # without the overhead of actually doing so. Think of it as OpenStruct
  # with some additional goodies.
  #
  # A Mash will look at the methods you pass it and perform operations
  # based on the following rules:
  #
  # * No punctuation: Returns the value of the hash for that key, or nil if none exists.
  # * Assignment (<tt>=</tt>): Sets the attribute of the given method name.
  # * Truthiness (<tt>?</tt>): Returns true or false depending on the truthiness of
  #   the attribute, or false if the key is not set.
  # * Bang (<tt>!</tt>): Forces the existence of this key, used for deep Mashes. Think of it
  #   as "touch" for mashes.
  # * Under Bang (<tt>_</tt>): Like Bang, but returns a new Mash rather than creating a key.
  #   Used to test existance in deep Mashes.
  #
  # == Basic Example
  #
  #   mash = Mash.new
  #   mash.name? # => false
  #   mash.name = "Bob"
  #   mash.name # => "Bob"
  #   mash.name? # => true
  #
  # == Hash Conversion  Example
  #
  #   hash = {:a => {:b => 23, :d => {:e => "abc"}}, :f => [{:g => 44, :h => 29}, 12]}
  #   mash = Mash.new(hash)
  #   mash.a.b # => 23
  #   mash.a.d.e # => "abc"
  #   mash.f.first.g # => 44
  #   mash.f.last # => 12
  #
  # == Bang Example
  #
  #   mash = Mash.new
  #   mash.author # => nil
  #   mash.author! # => <Mash>
  #
  #   mash = Mash.new
  #   mash.author!.name = "Michael Bleigh"
  #   mash.author # => <Mash name="Michael Bleigh">
  #
  # == Under Bang Example
  #
  #   mash = Mash.new
  #   mash.author # => nil
  #   mash.author_ # => <Mash>
  #   mash.author_.name # => nil
  #
  #   mash = Mash.new
  #   mash.author_.name = "Michael Bleigh"  (assigned to temp object)
  #   mash.author # => <Mash>
  #
  class Mash < Hash
    include Hashie::Extensions::RubyVersionCheck
    extend Hashie::Extensions::KeyConflictWarning

    ALLOWED_SUFFIXES = %w[? ! = _].freeze

    def self.load(path, options = {})
      @_mashes ||= new

      return @_mashes[path] if @_mashes.key?(path)
      raise ArgumentError, "The following file doesn't exist: #{path}" unless File.file?(path)

      options = options.dup
      parser = options.delete(:parser) { Hashie::Extensions::Parsers::YamlErbParser }
      @_mashes[path] = new(parser.perform(path, options)).freeze
    end

    def to_module(mash_method_name = :settings)
      mash = self
      Module.new do |m|
        m.send :define_method, mash_method_name.to_sym do
          mash
        end
      end
    end

    def with_accessors!
      extend Hashie::Extensions::Mash::DefineAccessors
    end

    alias to_s inspect

    # If you pass in an existing hash, it will
    # convert it to a Mash including recursively
    # descending into arrays and hashes, converting
    # them as well.
    def initialize(source_hash = nil, default = nil, &blk)
      deep_update(source_hash) if source_hash
      default ? super(default) : super(&blk)
    end

    # Creates a new anonymous subclass with key conflict
    # warnings disabled. You may pass an array of method
    # symbols to restrict the disabled warnings to.
    # Hashie::Mash.quiet.new(hash) all warnings disabled.
    # Hashie::Mash.quiet(:zip).new(hash) only zip warning
    # is disabled.
    def self.quiet(*method_keys)
      @memoized_classes ||= {}
      @memoized_classes[method_keys] ||= Class.new(self) do
        disable_warnings(*method_keys)
      end
    end

    class << self; alias [] new; end

    alias regular_reader []
    alias regular_writer []=

    # Retrieves an attribute set in the Mash. Will convert a key passed in
    # as a symbol to a string before retrieving.
    def custom_reader(key)
      default_proc.call(self, key) if default_proc && !key?(key)
      value = regular_reader(convert_key(key))
      yield value if block_given?
      value
    end

    # Sets an attribute in the Mash. Symbol keys will be converted to
    # strings before being set, and Hashes will be converted into Mashes
    # for nesting purposes.
    def custom_writer(key, value, convert = true) #:nodoc:
      log_built_in_message(key) if key.respond_to?(:to_sym) && log_collision?(key.to_sym)
      regular_writer(convert_key(key), convert ? convert_value(value) : value)
    end

    alias [] custom_reader
    alias []= custom_writer

    # This is the bang method reader, it will return a new Mash
    # if there isn't a value already assigned to the key requested.
    def initializing_reader(key)
      ck = convert_key(key)
      regular_writer(ck, self.class.new) unless key?(ck)
      regular_reader(ck)
    end

    # This is the under bang method reader, it will return a temporary new Mash
    # if there isn't a value already assigned to the key requested.
    def underbang_reader(key)
      ck = convert_key(key)
      if key?(ck)
        regular_reader(ck)
      else
        self.class.new
      end
    end

    def fetch(key, *args)
      super(convert_key(key), *args)
    end

    def delete(key)
      super(convert_key(key))
    end

    def values_at(*keys)
      super(*keys.map { |key| convert_key(key) })
    end

    # Returns a new instance of the class it was called on, using its keys as
    # values, and its values as keys. The new values and keys will always be
    # strings.
    def invert
      self.class.new(super)
    end

    # Returns a new instance of the class it was called on, containing elements
    # for which the given block returns false.
    def reject(&blk)
      self.class.new(super(&blk))
    end

    # Returns a new instance of the class it was called on, containing elements
    # for which the given block returns true.
    def select(&blk)
      self.class.new(super(&blk))
    end

    alias regular_dup dup
    # Duplicates the current mash as a new mash.
    def dup
      self.class.new(self, default, &default_proc)
    end

    alias regular_key? key?
    def key?(key)
      super(convert_key(key))
    end
    alias has_key? key?
    alias include? key?
    alias member? key?

    if with_minimum_ruby?('2.6.0')
      # Performs a deep_update on a duplicate of the
      # current mash.
      def deep_merge(*other_hashes, &blk)
        dup.deep_update(*other_hashes, &blk)
      end

      # Recursively merges this mash with the passed
      # in hash, merging each hash in the hierarchy.
      def deep_update(*other_hashes, &blk)
        other_hashes.each do |other_hash|
          _deep_update(other_hash, &blk)
        end
        self
      end
    else
      # Performs a deep_update on a duplicate of the
      # current mash.
      def deep_merge(other_hash, &blk)
        dup.deep_update(other_hash, &blk)
      end

      # Recursively merges this mash with the passed
      # in hash, merging each hash in the hierarchy.
      def deep_update(other_hash, &blk)
        _deep_update(other_hash, &blk)
        self
      end
    end

    # Alias these lexically so they get the correctly defined
    # #deep_merge and #deep_update based on ruby version.
    alias merge deep_merge
    alias deep_merge! deep_update
    alias update deep_update
    alias merge! update

    def _deep_update(other_hash, &blk)
      other_hash.each_pair do |k, v|
        key = convert_key(k)
        if v.is_a?(::Hash) && key?(key) && regular_reader(key).is_a?(Mash)
          custom_reader(key).deep_update(v, &blk)
        else
          value = convert_value(v, true)
          value = convert_value(yield(key, self[k], value), true) if blk && key?(k)
          custom_writer(key, value, false)
        end
      end
    end
    private :_deep_update

    # Assigns a value to a key
    def assign_property(name, value)
      self[name] = value
    end

    # Performs a shallow_update on a duplicate of the current mash
    def shallow_merge(other_hash)
      dup.shallow_update(other_hash)
    end

    # Merges (non-recursively) the hash from the argument,
    # changing the receiving hash
    def shallow_update(other_hash)
      other_hash.each_pair do |k, v|
        regular_writer(convert_key(k), convert_value(v, true))
      end
      self
    end

    def replace(other_hash)
      (keys - other_hash.keys).each { |key| delete(key) }
      other_hash.each { |key, value| self[key] = value }
      self
    end

    def respond_to_missing?(method_name, *args)
      return true if key?(method_name)
      suffix = method_suffix(method_name)
      if suffix
        true
      else
        super
      end
    end

    def prefix_method?(method_name)
      method_name = method_name.to_s
      method_name.end_with?(*ALLOWED_SUFFIXES) && key?(method_name.chop)
    end

    def method_missing(method_name, *args, &blk) # rubocop:disable Style/MethodMissing
      return self.[](method_name, &blk) if key?(method_name)
      name, suffix = method_name_and_suffix(method_name)
      case suffix
      when '='.freeze
        assign_property(name, args.first)
      when '?'.freeze
        !!self[name]
      when '!'.freeze
        initializing_reader(name)
      when '_'.freeze
        underbang_reader(name)
      else
        self[method_name]
      end
    end

    # play nice with ActiveSupport Array#extract_options!
    def extractable_options?
      true
    end

    # another ActiveSupport method, see issue #270
    def reverse_merge(other_hash)
      self.class.new(other_hash).merge(self)
    end

    with_minimum_ruby('2.3.0') do
      def dig(*keys)
        super(*keys.map { |key| convert_key(key) })
      end
    end

    with_minimum_ruby('2.4.0') do
      def transform_values(&blk)
        self.class.new(super(&blk))
      end

      # Returns a new instance of the class it was called on, with nil values
      # removed.
      def compact
        self.class.new(super)
      end
    end

    with_minimum_ruby('2.5.0') do
      def slice(*keys)
        string_keys = keys.map { |key| convert_key(key) }
        self.class.new(super(*string_keys))
      end

      def transform_keys(&blk)
        self.class.new(super(&blk))
      end
    end

    with_minimum_ruby('3.0.0') do
      def except(*keys)
        string_keys = keys.map { |key| convert_key(key) }
        self.class.new(super(*string_keys))
      end
    end

    protected

    def method_name_and_suffix(method_name)
      method_name = method_name.to_s
      if method_name.end_with?(*ALLOWED_SUFFIXES)
        [method_name[0..-2], method_name[-1]]
      else
        [method_name[0..-1], nil]
      end
    end

    def method_suffix(method_name)
      method_name = method_name.to_s
      method_name[-1] if method_name.end_with?(*ALLOWED_SUFFIXES)
    end

    def convert_key(key) #:nodoc:
      key.respond_to?(:to_sym) ? key.to_s : key
    end

    def convert_value(val, duping = false) #:nodoc:
      case val
      when self.class
        val.dup
      when Hash
        duping ? val.dup : val
      when ::Hash
        val = val.dup if duping
        self.class.new(val)
      when ::Array
        Array.new(val.map { |e| convert_value(e) })
      else
        val
      end
    end

    private

    def log_built_in_message(method_key)
      return if self.class.disable_warnings?(method_key)

      method_information = Hashie::Utils.method_information(method(method_key))

      Hashie.logger.warn(
        'You are setting a key that conflicts with a built-in method ' \
        "#{self.class}##{method_key} #{method_information}. " \
        'This can cause unexpected behavior when accessing the key as a ' \
        'property. You can still access the key via the #[] method.'
      )
    end

    def log_collision?(method_key)
      return unless method_key.is_a?(String) || method_key.is_a?(Symbol)
      return unless respond_to?(method_key)

      _, suffix = method_name_and_suffix(method_key)

      (!suffix || suffix == '='.freeze) &&
        !self.class.disable_warnings?(method_key) &&
        !(regular_key?(method_key) || regular_key?(method_key.to_s))
    end
  end
end
