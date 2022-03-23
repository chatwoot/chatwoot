class JsonbAttributesLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.empty?

    value.each do |key, attribute_value|
      case attribute_value.class.name
      when 'String'
        record.errors.add attribute, "#{key} length should be < 1500" if attribute_value.length > 1500
      when 'Integer'
        record.errors.add attribute, "#{key} value maximun limit should be < 9999999999" if attribute_value.length > 9_999_999_999
      end
    end
  end
end
