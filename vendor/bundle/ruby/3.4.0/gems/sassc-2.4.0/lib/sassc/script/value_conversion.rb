# frozen_string_literal: true

module SassC::Script::ValueConversion

  def self.from_native(native_value, options)
    case value_tag = SassC::Native.value_get_tag(native_value)
    when :sass_null
      # no-op
    when :sass_string
      value = SassC::Native.string_get_value(native_value)
      type = SassC::Native.string_get_type(native_value)
      argument = SassC::Script::Value::String.new(value, type)
      argument
    when :sass_boolean
      value = SassC::Native.boolean_get_value(native_value)
      argument = SassC::Script::Value::Bool.new(value)
      argument
    when :sass_number
      value = SassC::Native.number_get_value(native_value)
      unit = SassC::Native.number_get_unit(native_value)
      argument = SassC::Script::Value::Number.new(value, unit)
      argument
    when :sass_color
      red, green, blue, alpha = SassC::Native.color_get_r(native_value), SassC::Native.color_get_g(native_value), SassC::Native.color_get_b(native_value), SassC::Native.color_get_a(native_value)
      argument = SassC::Script::Value::Color.new(red:red, green:green, blue:blue, alpha:alpha)
      argument.options = options
      argument
    when :sass_map
      values = {}
      length = SassC::Native::map_get_length native_value
      (0..length-1).each do |index|
        key = SassC::Native::map_get_key(native_value, index)
        value = SassC::Native::map_get_value(native_value, index)
        values[from_native(key, options)] = from_native(value, options)
      end
      argument = SassC::Script::Value::Map.new values
      argument
    when :sass_list
      length = SassC::Native::list_get_length(native_value)
      items = (0...length).map do |index|
        native_item = SassC::Native::list_get_value(native_value, index)
        from_native(native_item, options)
      end
      SassC::Script::Value::List.new(items, separator: :space)
    else
      raise UnsupportedValue.new("Sass argument of type #{value_tag} unsupported")
    end
  end

  def self.to_native(value)
    case value_name = value.class.name.split("::").last
    when "String"
      SassC::Script::ValueConversion::String.new(value).to_native
    when "Color"
      SassC::Script::ValueConversion::Color.new(value).to_native
    when "Number"
      SassC::Script::ValueConversion::Number.new(value).to_native
    when "Map"
      SassC::Script::ValueConversion::Map.new(value).to_native
    when "List"
      SassC::Script::ValueConversion::List.new(value).to_native
    when "Bool"
      SassC::Script::ValueConversion::Bool.new(value).to_native
    else
      raise SassC::UnsupportedValue.new("Sass return type #{value_name} unsupported")
    end
  end

end
