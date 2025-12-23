class ValidDateRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "is invalid" unless valid_date_range?(value)
  end

  private

  def valid_date_range?(date_range)
    from_date_string, end_date_string = date_range.to_s.split("...")
    return true unless end_date_string # validated by other validator

    [from_date_string, end_date_string].all? { |date| valid_date?(date) }
  end

  def valid_date?(date)
    !!DateTime.parse(date.to_s)
  rescue ArgumentError
    false
  end
end
