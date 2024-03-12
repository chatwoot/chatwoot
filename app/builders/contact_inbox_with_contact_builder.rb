# This Builder will create a contact and contact inbox with specified attributes.
# If an existing identified contact exisits, it will be returned.
# for contact inbox logic it uses the contact inbox builder

class ContactInboxWithContactBuilder
  pattr_initialize [:inbox!, :contact_attributes!, :source_id, :hmac_verified]

  def perform
    find_or_create_contact_and_contact_inbox
  # in case of race conditions where contact is created by another thread
  # we will try to find the contact and create a contact inbox
  rescue ActiveRecord::RecordNotUnique
    find_or_create_contact_and_contact_inbox
  end

  def find_or_create_contact_and_contact_inbox
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id) if source_id.present?
    return @contact_inbox if @contact_inbox

    ActiveRecord::Base.transaction(requires_new: true) do
      build_contact_with_contact_inbox
      update_contact_avatar(@contact) unless @contact.avatar.attached?
      @contact_inbox
    end
  end

  private

  def build_contact_with_contact_inbox
    @contact = find_contact || create_contact
    @contact_inbox = create_contact_inbox
  end

  def account
    @account ||= inbox.account
  end

  def create_contact_inbox
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: @source_id,
      hmac_verified: hmac_verified
    ).perform
  end

  def update_contact_avatar(contact)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
  end

  def create_contact
    contact_params = build_contact_params
    account.contacts.create!(contact_params)
  end

  def build_contact_params
    {
      name: contact_name,
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      location: contact_location,
      country_code: contact_country_code,
      additional_attributes: contact_attributes[:additional_attributes],
      custom_attributes: contact_attributes[:custom_attributes]
    }
  end

  def contact_name
    contact_attributes[:name] || ::Haikunator.haikunate(1000)
  end

  def contact_location
    # TODO: Deprecate the additional_attributes['city'] in favor of country_code
    contact_attributes[:location] || contact_attributes.dig(:additional_attributes, 'city')
  end

  def contact_country_code
    # TODO: Deprecate the additional_attributes['country_code'] in favor of country_code
    contact_attributes[:country_code] || contact_attributes.dig(:additional_attributes, 'country_code')
  end

  def find_contact
    contact = find_contact_by_identifier(contact_attributes[:identifier])
    contact ||= find_contact_by_email(contact_attributes[:email])
    contact ||= find_contact_by_phone_number(contact_attributes[:phone_number])
    contact
  end

  def find_contact_by_identifier(identifier)
    return if identifier.blank?

    account.contacts.find_by(identifier: identifier)
  end

  def find_contact_by_email(email)
    return if email.blank?

    account.contacts.from_email(email)
  end

  def find_contact_by_phone_number(phone_number)
    return if phone_number.blank?

    account.contacts.find_by(phone_number: phone_number)
  end
end
