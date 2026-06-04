require 'phonelib'

class BrazilianNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    phone = Phonelib.parse(value)

    return if phone.country != 'BR' || phone.valid? || (phone.type == :mobile && phone.local_number.scan(/\d/).join.length = 11)

    record.errors.add(attribute, options[:message] || I18n.t('errors.contacts.phone_number.invalid'))
  end
end
