# frozen_string_literal: true

module Aws
  # @api private
  module Structure

    def initialize(values = {})
      values.each do |k, v|
        self[k] = v
      end
    end

    # @return [Boolean] Returns `true` if this structure has a value
    #   set for the given member.
    def key?(member_name)
      !self[member_name].nil?
    end

    # @return [Boolean] Returns `true` if all of the member values are `nil`.
    def empty?
      values.compact == []
    end

    # Deeply converts the Structure into a hash.  Structure members that
    # are `nil` are omitted from the resultant hash.
    #
    # You can call #orig_to_h to get vanilla #to_h behavior as defined
    # in stdlib Struct.
    #
    # @return [Hash]
    def to_h(obj = self, options = {})
      case obj
      when Struct
        obj.each_pair.with_object({}) do |(member, value), hash|
          member = member.to_s if options[:as_json]
          hash[member] = to_hash(value, options) unless value.nil?
        end
      when Hash
        obj.each.with_object({}) do |(key, value), hash|
          key = key.to_s if options[:as_json]
          hash[key] = to_hash(value, options)
        end
      when Array
        obj.collect { |value| to_hash(value, options) }
      else
        obj
      end
    end
    alias to_hash to_h

    # Wraps the default #to_s logic with filtering of sensitive parameters.
    def to_s(obj = self)
      Aws::Log::ParamFilter.new.filter(obj, obj.class).to_s
    end

    class << self

      # @api private
      def new(*args)
        if args.empty?
          Aws::EmptyStructure
        else
          struct = Struct.new(*args)
          struct.send(:include, Aws::Structure)
          struct
        end
      end

      # @api private
      def self.included(base_class)
        base_class.send(:undef_method, :each)
      end

    end

    module Union
      def member
        self.members.select { |k| self[k] != nil }.first
      end

      def value
        self[member] if member
      end
    end
  end

  # @api private
  class EmptyStructure < Struct.new('AwsEmptyStructure')
    include(Aws::Structure)
  end
end
