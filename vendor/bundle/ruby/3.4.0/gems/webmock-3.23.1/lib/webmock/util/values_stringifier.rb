# frozen_string_literal: true

class WebMock::Util::ValuesStringifier
  def self.stringify_values(value)
    case value
    when String, Numeric, TrueClass, FalseClass
      value.to_s
    when Hash
      Hash[
        value.map do |k, v|
          [k, stringify_values(v)]
        end
      ]
    when Array
      value.map do |v|
        stringify_values(v)
      end
    else
      value
    end
  end
end
