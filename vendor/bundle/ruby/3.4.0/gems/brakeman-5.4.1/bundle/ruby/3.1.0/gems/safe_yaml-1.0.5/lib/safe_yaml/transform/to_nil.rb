module SafeYAML
  class Transform
    class ToNil
      include TransformationMap

      set_predefined_values({
        ""      => nil,
        "~"     => nil,
        "null"  => nil
      })

      def transform?(value)
        return false if value.length > 4
        return PREDEFINED_VALUES.include?(value), PREDEFINED_VALUES[value]
      end
    end
  end
end
