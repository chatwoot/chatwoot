class ContactBuilder
  pattr_initialize [:source_id!, :inbox!, :contact_attributes!]

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
      source_id: source_id
    )
  end

  def update_contact_avatar(contact)
    ::ContactAvatarJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
  end

  def create_contact
    account.contacts.create!(
      name: contact_attributes[:name],
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      additional_attributes: contact_attributes[:additional_attributes]
    )
  end

  def find_contact
    contact = nil

    contact = account.contacts.find_by(identifier: contact_attributes[:identifier]) if contact_attributes[:identifier].present?

    contact ||= account.contacts.find_by(email: contact_attributes[:email]) if contact_attributes[:email].present?

    contact ||= account.contacts.find_by(phone_number: contact_attributes[:phone_number]) if contact_attributes[:phone_number].present?

    contact
  end

  def build_contact_inbox
    ActiveRecord::Base.transaction do
      contact = find_contact || create_contact
      contact_inbox = create_contact_inbox(contact)
      update_contact_avatar(contact)
      contact_inbox
    rescue StandardError => e
      Rails.logger.info e
    end
  end
end
