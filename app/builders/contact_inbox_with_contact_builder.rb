# This Builder will create a contact and contact inbox with specified attributes.
# If an existing identified contact exisits, it will be returned.
# for contact inbox logic it uses the contact inbox builder

class ContactInboxWithContactBuilder
  pattr_initialize [:inbox!, :contact_attributes!, :source_id, :hmac_verified]

  def perform
    Rails.logger.info "[ContactInboxWithContactBuilder] Starting contact creation process - source_id: #{source_id}, inbox_id: #{inbox.id}, contact_attributes: #{contact_attributes.inspect}"

    result = find_or_create_contact_and_contact_inbox

    Rails.logger.info "[ContactInboxWithContactBuilder] Successfully created/found contact_inbox - id: #{result&.id}, contact_id: #{result&.contact_id}"
    result
  # in case of race conditions where contact is created by another thread
  # we will try to find the contact and create a contact inbox
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.warn "[ContactInboxWithContactBuilder] Race condition detected, retrying - error: #{e.message}"
    find_or_create_contact_and_contact_inbox
  rescue StandardError => e
    Rails.logger.error "[ContactInboxWithContactBuilder] Failed to create contact - error: #{e.message}, backtrace: #{e.backtrace.first(5).join(', ')}"
    raise e
  end

  def find_or_create_contact_and_contact_inbox
    Rails.logger.debug { "[ContactInboxWithContactBuilder] Looking for existing contact_inbox with source_id: #{source_id}" }

    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id) if source_id.present?
    if @contact_inbox
      Rails.logger.info "[ContactInboxWithContactBuilder] Found existing contact_inbox - id: #{@contact_inbox.id}, contact_id: #{@contact_inbox.contact_id}"
      return @contact_inbox
    end

    Rails.logger.info '[ContactInboxWithContactBuilder] No existing contact_inbox found, creating new one'

    ActiveRecord::Base.transaction(requires_new: true) do
      build_contact_with_contact_inbox
    end
    update_contact_avatar(@contact) unless @contact.avatar.attached?

    Rails.logger.info "[ContactInboxWithContactBuilder] Transaction completed - contact_inbox_id: #{@contact_inbox&.id}, contact_id: #{@contact&.id}"
    @contact_inbox
  end

  private

  def build_contact_with_contact_inbox
    Rails.logger.debug '[ContactInboxWithContactBuilder] Building contact and contact_inbox'

    @contact = find_contact || create_contact
    Rails.logger.info "[ContactInboxWithContactBuilder] Contact resolved - id: #{@contact.id}, found_existing: #{@contact.persisted? && !@contact.created_at.nil? && @contact.created_at < 1.second.ago}"

    @contact_inbox = create_contact_inbox
    Rails.logger.info "[ContactInboxWithContactBuilder] Contact_inbox created - id: #{@contact_inbox.id}"
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
    Rails.logger.info '[ContactInboxWithContactBuilder] Creating new contact with attributes: ' \
                      "#{contact_attributes.except(:additional_attributes, :custom_attributes).inspect}"

    contact = account.contacts.create!(
      name: contact_attributes[:name] || ::Haikunator.haikunate(1000),
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      additional_attributes: contact_attributes[:additional_attributes],
      custom_attributes: contact_attributes[:custom_attributes]
    )

    Rails.logger.info "[ContactInboxWithContactBuilder] Contact created successfully - id: #{contact.id}, name: '#{contact.name}'"
    contact
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[ContactInboxWithContactBuilder] Contact creation failed - validation errors: #{e.record.errors.full_messages.join(', ')}"
    raise e
  end

  def find_contact
    Rails.logger.debug do
      "[ContactInboxWithContactBuilder] Searching for existing contact using identifier: #{contact_attributes[:identifier]}, " \
        "email: #{contact_attributes[:email]}, phone: #{contact_attributes[:phone_number]}"
    end

    contact = find_contact_by_identifier(contact_attributes[:identifier])
    if contact
      Rails.logger.info "[ContactInboxWithContactBuilder] Found contact by identifier - id: #{contact.id}"
      return contact
    end

    contact ||= find_contact_by_email(contact_attributes[:email])
    if contact
      Rails.logger.info "[ContactInboxWithContactBuilder] Found contact by email - id: #{contact.id}"
      return contact
    end

    contact ||= find_contact_by_phone_number(contact_attributes[:phone_number])
    if contact
      Rails.logger.info "[ContactInboxWithContactBuilder] Found contact by phone number - id: #{contact.id}"
      return contact
    end

    contact ||= find_contact_by_instagram_source_id(source_id) if instagram_channel?
    if contact
      Rails.logger.info "[ContactInboxWithContactBuilder] Found contact by Instagram source_id - id: #{contact.id}"
      return contact
    end

    Rails.logger.info '[ContactInboxWithContactBuilder] No existing contact found, will create new one'
    contact
  end

  def instagram_channel?
    inbox.channel_type == 'Channel::Instagram'
  end

  # There might be existing contact_inboxes created through Channel::FacebookPage
  # with the same Instagram source_id. New Instagram interactions should create fresh contact_inboxes
  # while still reusing contacts if found in Facebook channels so that we can create
  # new conversations with the same contact.
  def find_contact_by_instagram_source_id(instagram_id)
    return if instagram_id.blank?

    existing_contact_inbox = ContactInbox.joins(:inbox)
                                         .where(source_id: instagram_id)
                                         .where(
                                           'inboxes.channel_type = ? AND inboxes.account_id = ?',
                                           'Channel::FacebookPage',
                                           account.id
                                         ).first

    existing_contact_inbox&.contact
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
