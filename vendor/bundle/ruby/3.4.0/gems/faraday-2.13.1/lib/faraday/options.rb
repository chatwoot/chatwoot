# frozen_string_literal: true

module Faraday
  # Subclasses Struct with some special helpers for converting from a Hash to
  # a Struct.
  class Options < Struct
    # Public
    def self.from(value)
      value ? new.update(value) : new
    end

    # Public
    def each
      return to_enum(:each) unless block_given?

      members.each do |key|
        yield(key.to_sym, send(key))
      end
    end

    # Public
    def update(obj)
      obj.each do |key, value|
        sub_options = self.class.options_for(key)
        if sub_options
          new_value = sub_options.from(value) if value
        elsif value.is_a?(Hash)
          new_value = value.dup
        else
          new_value = value
        end

        send(:"#{key}=", new_value) unless new_value.nil?
      end
      self
    end

    # Public
    def delete(key)
      value = send(key)
      send(:"#{key}=", nil)
      value
    end

    # Public
    def clear
      members.each { |member| delete(member) }
    end

    # Public
    def merge!(other)
      other.each do |key, other_value|
        self_value = send(key)
        sub_options = self.class.options_for(key)
        new_value = if self_value && sub_options && other_value
                      self_value.merge(other_value)
                    else
                      other_value
                    end
        send(:"#{key}=", new_value) unless new_value.nil?
      end
      self
    end

    # Public
    def merge(other)
      dup.merge!(other)
    end

    # Public
    def deep_dup
      self.class.from(self)
    end

    # Public
    def fetch(key, *args)
      unless symbolized_key_set.include?(key.to_sym)
        key_setter = "#{key}="
        if !args.empty?
          send(key_setter, args.first)
        elsif block_given?
          send(key_setter, yield(key))
        else
          raise self.class.fetch_error_class, "key not found: #{key.inspect}"
        end
      end
      send(key)
    end

    # Public
    def values_at(*keys)
      keys.map { |key| send(key) }
    end

    # Public
    def keys
      members.reject { |member| send(member).nil? }
    end

    # Public
    def empty?
      keys.empty?
    end

    # Public
    def each_key(&block)
      return to_enum(:each_key) unless block

      keys.each(&block)
    end

    # Public
    def key?(key)
      keys.include?(key)
    end

    alias has_key? key?

    # Public
    def each_value(&block)
      return to_enum(:each_value) unless block

      values.each(&block)
    end

    # Public
    def value?(value)
      values.include?(value)
    end

    alias has_value? value?

    # Public
    def to_hash
      hash = {}
      members.each do |key|
        value = send(key)
        hash[key.to_sym] = value unless value.nil?
      end
      hash
    end

    # Internal
    def inspect
      values = []
      members.each do |member|
        value = send(member)
        values << "#{member}=#{value.inspect}" if value
      end
      values = values.empty? ? '(empty)' : values.join(', ')

      %(#<#{self.class} #{values}>)
    end

    # Internal
    def self.options(mapping)
      attribute_options.update(mapping)
    end

    # Internal
    def self.options_for(key)
      attribute_options[key]
    end

    # Internal
    def self.attribute_options
      @attribute_options ||= {}
    end

    def self.memoized(key, &block)
      unless block
        raise ArgumentError, '#memoized must be called with a block'
      end

      memoized_attributes[key.to_sym] = block
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        remove_method(key) if method_defined?(key, false)
        def #{key}() self[:#{key}]; end
      RUBY
    end

    def self.memoized_attributes
      @memoized_attributes ||= {}
    end

    def [](key)
      key = key.to_sym
      if (method = self.class.memoized_attributes[key])
        super(key) || (self[key] = instance_eval(&method))
      else
        super
      end
    end

    def symbolized_key_set
      @symbolized_key_set ||= Set.new(keys.map(&:to_sym))
    end

    def self.inherited(subclass)
      super
      subclass.attribute_options.update(attribute_options)
      subclass.memoized_attributes.update(memoized_attributes)
    end

    def self.fetch_error_class
      @fetch_error_class ||= if Object.const_defined?(:KeyError)
                               ::KeyError
                             else
                               ::IndexError
                             end
    end
  end
end

require 'faraday/options/request_options'
require 'faraday/options/ssl_options'
require 'faraday/options/proxy_options'
require 'faraday/options/connection_options'
require 'faraday/options/env'
