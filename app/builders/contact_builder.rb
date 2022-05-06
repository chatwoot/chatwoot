class ContactBuilder
  pattr_initialize [:source_id!, :inbox!, :contact_attributes!, :hmac_verified]

  def perform
    contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
    return contact_inbox if contact_inbox

    build_contact_inbox
  end

  private

  def account
    @account ||= inbox.account
  end

  def create_contact_inbox(contact)
    ::ContactInbox.create!(
      contact_id: contact.id,
      inbox_id: inbox.id,
      source_id: source_id,
      hmac_verified: hmac_verified || false
    )
  end

  def update_contact_avatar(contact)
    ::ContactAvatarJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
  end

  def create_contact
    account.contacts.create!(
      name: contact_attributes[:name] || ::Haikunator.haikunate(1000),
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      additional_attributes: contact_attributes[:additional_attributes],
      custom_attributes: contact_attributes[:custom_attributes]
    )
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

    account.contacts.find_by(email: email.downcase)
  end

  def find_contact_by_phone_number(phone_number)
    return if phone_number.blank?

    account.contacts.find_by(phone_number: phone_number)
  end

  def build_contact_inbox
    ActiveRecord::Base.transaction do
      contact = find_contact || create_contact
      contact_inbox = create_contact_inbox(contact)
      update_contact_avatar(contact)
      contact_inbox
    rescue StandardError => e
      Rails.logger.error e
      raise e
    end
  end
end
