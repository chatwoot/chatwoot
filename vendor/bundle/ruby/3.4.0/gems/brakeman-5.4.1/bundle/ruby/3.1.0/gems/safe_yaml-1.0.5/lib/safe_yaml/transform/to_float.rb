module SafeYAML
  class Transform
    class ToFloat
      Infinity = 1.0 / 0.0
      NaN = 0.0 / 0.0

      PREDEFINED_VALUES = {
        ".inf"  => Infinity,
        ".Inf"  => Infinity,
        ".INF"  => Infinity,
        "-.inf" => -Infinity,
        "-.Inf" => -Infinity,
        "-.INF" => -Infinity,
        ".nan"  => NaN,
        ".NaN"  => NaN,
        ".NAN"  => NaN,
      }.freeze

      MATCHER = /\A[-+]?(?:\d[\d_]*)?\.[\d_]+(?:[eE][-+][\d]+)?\Z/.freeze

      def transform?(value)
        return true, Float(value) if MATCHER.match(value)
        try_edge_cases?(value)
      end

      def try_edge_cases?(value)
        return true, PREDEFINED_VALUES[value] if PREDEFINED_VALUES.include?(value)
        return true, Parse::Sexagesimal.value(value) if Parse::Sexagesimal::FLOAT_MATCHER.match(value)
        return false
      end
    end
  end
end
