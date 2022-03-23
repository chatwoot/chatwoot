class JsonbAttributesLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.empty?

    value.each do |key, attribute_value|
      next unless value.is_a?(String)

      record.errors.add attribute, "#{key} length should be < 1500" if attribute_value.length > 1500
    end
  end
end
