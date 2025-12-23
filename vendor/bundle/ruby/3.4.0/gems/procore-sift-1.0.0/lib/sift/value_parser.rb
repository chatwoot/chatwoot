module Sift
  class ValueParser
    def initialize(value:, type: nil, options: {})
      @value = value
      @supports_boolean = options.fetch(:supports_boolean, false)
      @supports_ranges = options.fetch(:supports_ranges, false)
      @supports_json = options.fetch(:supports_json, false)
      @supports_json_object = options.fetch(:supports_json_object, false)
      @value = normalized_value(value, type)
    end

    def parse
      @_result ||=
        if parse_as_range?
          range_value
        elsif parse_as_boolean?
          boolean_value
        elsif parse_as_json?
          supports_json_object ? parse_json_and_values : array_from_json
        else
          value
        end
    end

    def parse_json(string)
      JSON.parse(string)
    rescue JSON::ParserError
      string
    end

    def parse_json_and_values
      parsed_jsonb = parse_json(value)
      return parsed_jsonb if parsed_jsonb.is_a?(Array) || parsed_jsonb.is_a?(String)

      parsed_jsonb.each_with_object({}) do |key_value, hash|
        key   = key_value.first
        value = key_value.last
        hash[key] = value.is_a?(String) ? parse_json(value) : value
      end
    end

    def array_from_json
      result = parse_json(value)
      if result.is_a?(Array)
        result
      else
        value
      end
    end

    private

    attr_reader :value, :type, :supports_boolean, :supports_json, :supports_json_object, :supports_ranges

    def parse_as_range?(raw_value=value)
      supports_ranges && raw_value.to_s.include?("...")
    end

    def range_value
      Range.new(*value.split("..."))
    end

    def parse_as_json?
      supports_json && value.is_a?(String)
    end

    def parse_as_boolean?
      supports_boolean
    end

    def boolean_value
      ActiveRecord::Type::Boolean.new.cast(value)
    end

    def normalized_value(raw_value, type)
      if type == :datetime && parse_as_range?(raw_value)
        normalized_date_range(raw_value)
      else
        raw_value
      end
    end

    def normalized_date_range(raw_value)
      from_date_string, end_date_string = raw_value.split("...")
      return unless end_date_string

      parsed_dates = [from_date_string, end_date_string].map do |date_string|
        begin
          DateTime.parse(date_string.to_s)
        rescue StandardError
          date_string
        end
      end

      parsed_dates.join("...")
    end
  end
end
