class ValidJsonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "must be a valid JSON" unless valid_json?(value)
  end

  private

  def valid_json?(value)
    value = value.strip if value.is_a?(String)
    JSON.parse(value)
  rescue JSON::ParserError
    false
  end
end
