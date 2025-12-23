module SafeYAML
  class Parse
    class Sexagesimal
      INTEGER_MATCHER = /\A[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\Z/.freeze
      FLOAT_MATCHER = /\A[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*\Z/.freeze

      def self.value(value)
        before_decimal, after_decimal = value.split(".")

        whole_part = 0
        multiplier = 1

        before_decimal = before_decimal.split(":")
        until before_decimal.empty?
          whole_part += (Float(before_decimal.pop) * multiplier)
          multiplier *= 60
        end

        result = whole_part
        result += Float("." + after_decimal) unless after_decimal.nil?
        result *= -1 if value[0] == "-"
        result
      end
    end
  end
end
