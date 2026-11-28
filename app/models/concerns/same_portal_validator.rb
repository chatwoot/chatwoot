class SamePortalValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if record.public_send(options[:association])&.portal_id == record.portal_id

    record.errors.add(attribute, :invalid)
  end
end
