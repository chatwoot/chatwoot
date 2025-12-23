module SafeYAML
  class Transform
    class ToDate
      def transform?(value)
        return true, Date.parse(value) if Parse::Date::DATE_MATCHER.match(value)
        return true, Parse::Date.value(value) if Parse::Date::TIME_MATCHER.match(value)
        false
      rescue ArgumentError
        return true, value
      end
    end
  end
end
