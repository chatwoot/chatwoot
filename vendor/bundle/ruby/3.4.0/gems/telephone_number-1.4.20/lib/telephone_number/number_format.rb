module TelephoneNumber
  class NumberFormat

    attr_reader :pattern, :leading_digits, :format, :national_prefix_formatting_rule, :intl_format

    def initialize(data_hash, country_prefix_formatting_rule)
      @pattern = Regexp.new(data_hash[:pattern]) if data_hash[:pattern]
      @leading_digits = Regexp.new(data_hash[:leading_digits]) if data_hash[:leading_digits]
      @format = data_hash[:format]
      @intl_format = data_hash[:intl_format]
      @national_prefix_formatting_rule = data_hash[:national_prefix_formatting_rule] || country_prefix_formatting_rule
    end
  end
end
