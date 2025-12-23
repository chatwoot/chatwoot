module SafeYAML
  class Transform
    class ToBoolean
      include TransformationMap

      set_predefined_values({
        "yes"   => true,
        "on"    => true,
        "true"  => true,
        "no"    => false,
        "off"   => false,
        "false" => false
      })

      def transform?(value)
        return false if value.length > 5
        return PREDEFINED_VALUES.include?(value), PREDEFINED_VALUES[value]
      end
    end
  end
end
