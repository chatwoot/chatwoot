# A contact created from a phone-only payload is named after its own number. Replace that
# placeholder the first time a provider tells us who the person actually is, and leave a name
# a human would recognise alone.
class Contacts::PlaceholderNameUpdater
  pattr_initialize [:contact!, :name!, :phone_numbers!]

  def perform
    return if name.blank? || contact.name == name
    return unless placeholder_name?

    contact.update!(name: name)
  end

  private

  def placeholder_name?
    Array(phone_numbers).compact_blank.uniq.any? do |number|
      contact.name == number || contact.name == TelephoneNumber.parse(number).international_number
    end
  end
end
