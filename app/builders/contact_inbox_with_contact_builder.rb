# This Builder will create a contact and contact inbox with specified attributes.
# If an existing identified contact exisits, it will be returned.
# for contact inbox logic it uses the contact inbox builder

class ContactInboxWithContactBuilder
  pattr_initialize [:inbox!, :contact_attributes!, :source_id, :hmac_verified]

  def perform
    merge_unoapi_duplicate_contact
    find_or_create_contact_and_contact_inbox
  # in case of race conditions where contact is created by another thread
  # we will try to find the contact and create a contact inbox
  rescue ActiveRecord::RecordNotUnique
    find_or_create_contact_and_contact_inbox
  end

  def find_or_create_contact_and_contact_inbox
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id) if source_id.present?
    if @contact_inbox
      update_contact_attributes(@contact_inbox.contact)
      update_contact_avatar(@contact_inbox.contact)
      return @contact_inbox
    end

    ActiveRecord::Base.transaction(requires_new: true) do
      build_contact_with_contact_inbox
      update_contact_avatar(@contact)
    end

    @contact_inbox
  end

  def merge_unoapi_duplicate_contact
    return unless inbox.channel_type == 'Channel::Whatsapp'
    return unless inbox.channel.provider == 'unoapi'

    Whatsapp::Unoapi::GroupParticipantContactMerger.new(account: account, inbox: inbox).perform(
      participant: {
        wa_id: unoapi_participant_wa_id,
        user_id: contact_attributes[:bsuid],
        username: contact_attributes[:whatsapp_username],
        name: contact_attributes[:name],
        picture: contact_attributes[:avatar_url]
      },
      source_id: source_id.to_s
    )
  end

  private

  def unoapi_participant_wa_id
    contact_attributes[:phone_number].to_s.gsub(/\D/, '').presence || source_id
  end

  def build_contact_with_contact_inbox
    @contact = find_contact || create_contact
    update_contact_attributes(@contact)
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
    ::Avatar::AvatarFromUrlJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url].present?
  end

  def create_contact
    account.contacts.create!(
      name: contact_attributes[:name] || ::Haikunator.haikunate(1000),
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      bsuid: contact_attributes[:bsuid],
      whatsapp_username: contact_attributes[:whatsapp_username],
      identifier: contact_attributes[:identifier],
      additional_attributes: contact_attributes[:additional_attributes],
      custom_attributes: contact_attributes[:custom_attributes]
    )
  end

  def find_contact
    contact = find_contact_by_bsuid(contact_attributes[:bsuid])
    contact ||= find_contact_by_identifier(contact_attributes[:identifier])
    contact ||= find_contact_by_email(contact_attributes[:email])
    contact ||= find_contact_by_phone_number(contact_attributes[:phone_number])
    contact ||= find_contact_by_instagram_source_id(source_id) if instagram_channel?

    contact
  end

  def update_contact_attributes(contact)
    attrs = {
      bsuid: missing_attribute(contact.bsuid, contact_attributes[:bsuid]),
      whatsapp_username: changed_attribute(contact.whatsapp_username, contact_attributes[:whatsapp_username]),
      phone_number: missing_attribute(contact.phone_number, contact_attributes[:phone_number]),
      name: missing_attribute(contact.name, contact_attributes[:name])
    }.compact

    sanitize_contact_email(contact) if attrs.present?
    update_contact(contact, attrs) if attrs.present?
  end

  def update_contact(contact, attrs)
    return contact.update_columns(safe_legacy_unoapi_attrs(contact, attrs).merge(updated_at: Time.current)) if legacy_unoapi_duplicate_phone?(contact)

    contact.update!(attrs)
  end

  def safe_legacy_unoapi_attrs(contact, attrs)
    attrs = attrs.except(:phone_number) if duplicate_phone_number?(attrs[:phone_number].presence || contact.phone_number, contact)
    attrs = attrs.except(:bsuid) if duplicate_bsuid?(attrs[:bsuid], contact)
    attrs
  end

  def legacy_unoapi_duplicate_phone?(contact)
    unoapi_whatsapp_channel? && duplicate_phone_number?(contact.phone_number, contact)
  end

  def unoapi_whatsapp_channel?
    inbox.channel_type == 'Channel::Whatsapp' && inbox.channel.provider == 'unoapi'
  end

  def duplicate_phone_number?(phone_number, contact)
    return false if phone_number.blank?

    account.contacts.where(phone_number: phone_number).where.not(id: contact.id).exists?
  end

  def duplicate_bsuid?(bsuid, contact)
    return false if bsuid.blank?

    account.contacts.where(bsuid: bsuid).where.not(id: contact.id).exists?
  end

  def sanitize_contact_email(contact)
    return if contact.email.blank? || valid_contact_email?(contact.email)

    Rails.logger.info("[CONTACT_INBOX] clearing invalid contact email contact_id=#{contact.id} email=#{contact.email}")
    contact.update_columns(email: nil, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def valid_contact_email?(email)
    email.match?(Devise.email_regexp) || email.end_with?('@lid') || email.end_with?('@g.us')
  end

  def missing_attribute(current_value, new_value)
    new_value if current_value.blank? && new_value.present?
  end

  def changed_attribute(current_value, new_value)
    new_value if new_value.present? && current_value != new_value
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

  def find_contact_by_bsuid(bsuid)
    return if bsuid.blank?

    account.contacts.find_by(bsuid: bsuid)
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
