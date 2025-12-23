# frozen_string_literal: true

module Liquid
  module Utils
    def self.slice_collection(collection, from, to)
      if (from != 0 || !to.nil?) && collection.respond_to?(:load_slice)
        collection.load_slice(from, to)
      else
        slice_collection_using_each(collection, from, to)
      end
    end

    def self.slice_collection_using_each(collection, from, to)
      segments = []
      index    = 0

      # Maintains Ruby 1.8.7 String#each behaviour on 1.9
      if collection.is_a?(String)
        return collection.empty? ? [] : [collection]
      end
      return [] unless collection.respond_to?(:each)

      collection.each do |item|
        if to && to <= index
          break
        end

        if from <= index
          segments << item
        end

        index += 1
      end

      segments
    end

    def self.to_integer(num)
      return num if num.is_a?(Integer)
      num = num.to_s
      begin
        Integer(num)
      rescue ::ArgumentError
        raise Liquid::ArgumentError, "invalid integer"
      end
    end

    def self.to_number(obj)
      case obj
      when Float
        BigDecimal(obj.to_s)
      when Numeric
        obj
      when String
        /\A-?\d+\.\d+\z/.match?(obj.strip) ? BigDecimal(obj) : obj.to_i
      else
        if obj.respond_to?(:to_number)
          obj.to_number
        else
          0
        end
      end
    end

    def self.to_date(obj)
      return obj if obj.respond_to?(:strftime)

      if obj.is_a?(String)
        return nil if obj.empty?
        obj = obj.downcase
      end

      case obj
      when 'now', 'today'
        Time.now
      when /\A\d+\z/, Integer
        Time.at(obj.to_i)
      when String
        Time.parse(obj)
      end
    rescue ::ArgumentError
      nil
    end

    def self.to_liquid_value(obj)
      # Enable "obj" to represent itself as a primitive value like integer, string, or boolean
      return obj.to_liquid_value if obj.respond_to?(:to_liquid_value)

      # Otherwise return the object itself
      obj
    end
  end
end
