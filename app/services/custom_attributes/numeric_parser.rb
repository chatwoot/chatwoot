# frozen_string_literal: true

# Locale-safe parse for number/currency/percent custom attributes.
# Returns Float or nil (never 0 for garbage — callers skip nil in Sum/Avg).
module CustomAttributes
  module NumericParser
    module_function

    def parse(value)
      return value.to_f if value.is_a?(Numeric)
      return nil if value.nil?

      str = value.to_s.strip
      return nil if str.empty?

      str = str.gsub(/[^\d,.\-]/, '')
      return nil if str.empty? || str == '-' || str == '.' || str == ','

      if str.include?(',') && str.include?('.')
        str = if str.rindex(',') > str.rindex('.')
                # European thousands + decimal: 1.000,50
                str.gsub('.', '').tr(',', '.')
              else
                # US thousands + decimal: 1,000.50
                str.gsub(',', '')
              end
      elsif str.include?(',')
        parts = str.split(',')
        str = if parts.length == 2 && parts[1].length.between?(1, 2)
                # Decimal comma: 1000,00 / 10,5
                str.tr(',', '.')
              else
                # Thousands commas: 1,000 / 1,000,000
                str.gsub(',', '')
              end
      end

      Float(str)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
