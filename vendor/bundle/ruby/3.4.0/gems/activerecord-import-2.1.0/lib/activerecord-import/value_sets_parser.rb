# frozen_string_literal: true

require 'active_support/core_ext/array'

module ActiveRecord::Import
  class ValueSetTooLargeError < StandardError
    attr_reader :size

    def initialize(msg = "Value set exceeds max size", size = 0)
      @size = size
      super(msg)
    end
  end

  class ValueSetsBytesParser
    attr_reader :reserved_bytes, :max_bytes, :values

    def self.parse(values, options)
      new(values, options).parse
    end

    def initialize(values, options)
      @values = values
      @reserved_bytes = options[:reserved_bytes] || 0
      @max_bytes = options.fetch(:max_bytes) { default_max_bytes }
    end

    def parse
      value_sets = []
      arr = []
      current_size = 0
      values.each_with_index do |val, i|
        comma_bytes = arr.size
        insert_size = reserved_bytes + val.bytesize

        if insert_size > max_bytes
          raise ValueSetTooLargeError.new("#{insert_size} bytes exceeds the max allowed for an insert [#{@max_bytes}]", insert_size)
        end

        bytes_thus_far = reserved_bytes + current_size + val.bytesize + comma_bytes
        if bytes_thus_far <= max_bytes
          current_size += val.bytesize
          arr << val
        else
          value_sets << arr
          arr = [val]
          current_size = val.bytesize
        end

        # if we're on the last iteration push whatever we have in arr to value_sets
        value_sets << arr if i == (values.size - 1)
      end

      value_sets
    end

    private

    def default_max_bytes
      values_in_bytes = values.sum(&:bytesize)
      comma_separated_bytes = values.size - 1
      reserved_bytes + values_in_bytes + comma_separated_bytes
    end
  end

  class ValueSetsRecordsParser
    attr_reader :max_records, :values

    def self.parse(values, options)
      new(values, options).parse
    end

    def initialize(values, options)
      @values = values
      @max_records = options[:max_records]
    end

    def parse
      @values.in_groups_of(max_records, false)
    end
  end
end
