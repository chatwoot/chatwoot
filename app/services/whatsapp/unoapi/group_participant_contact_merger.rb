class Whatsapp::Unoapi::GroupParticipantContactMerger
  def initialize(account:, inbox:, conversation: nil)
    @account = account
    @inbox = inbox
    @conversation = conversation
  end

  def perform(participant:, source_id:)
    bsuid = participant_bsuid(participant)
    return if bsuid.blank?

    phone_contact = phone_source?(source_id) ? participant_phone_contact(participant, source_id) : compatible_group_phone_contact(participant)
    lid_contact = participant_lid_contact(bsuid)
    return enrich_phone_contact(phone_contact, participant) if phone_contact.present? && lid_contact.blank?
    return if contacts_not_mergeable?(phone_contact, lid_contact)

    merge_contacts(phone_contact, lid_contact, participant, source_id)
  end

  def perform_from_group_payload(group_payload)
    return if group_payload[:sender_phone].blank? || group_payload[:sender_bsuid].blank?

    perform(
      participant: {
        wa_id: group_payload[:sender_phone],
        user_id: group_payload[:sender_bsuid],
        username: group_payload[:sender_username],
        name: group_payload[:sender_name],
        picture: group_payload[:sender_picture]
      },
      source_id: group_payload[:sender_phone]
    )
  end

  private

  def phone_source?(source_id)
    source_id.exclude?('@')
  end

  def contacts_not_mergeable?(phone_contact, lid_contact)
    return true if phone_contact.blank? || lid_contact.blank?
    return true if phone_contact.id == lid_contact.id

    phone_contact.bsuid.present? && lid_contact.bsuid.present? && phone_contact.bsuid != lid_contact.bsuid
  end

  def merge_contacts(phone_contact, lid_contact, participant, source_id)
    ActiveRecord::Base.transaction do
      sanitize_contact_email(phone_contact)
      sanitize_contact_email(lid_contact)
      update_phone_number(phone_contact, participant, source_id)
      lid_attributes = lid_contact_attributes(phone_contact, lid_contact, participant)
      merge_group_contacts(lid_contact, phone_contact)

      ContactMergeAction.new(account: @account, base_contact: phone_contact, mergee_contact: lid_contact).perform
      merge_lid_contact_attributes(phone_contact, lid_attributes)
    end
  end

  def enrich_phone_contact(phone_contact, participant)
    sanitize_contact_email(phone_contact)
    merge_lid_contact_attributes(
      phone_contact,
      {
        bsuid: participant_bsuid(participant),
        whatsapp_username: participant[:username].presence
      }.compact
    )
  end

  def update_phone_number(contact, participant, source_id)
    phone_number = participant_phone_number(participant, source_id)
    return if phone_number.blank? || contact.phone_number == phone_number

    contact.update_columns(phone_number: phone_number, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def participant_phone_contact(participant, source_id)
    phone_number = participant_phone_number(participant, source_id)

    @inbox.contact_inboxes.find_by(source_id: source_id)&.contact ||
      @inbox.contact_inboxes.find_by(source_id: phone_number.to_s.delete('+'))&.contact ||
      Contact.find_by(account_id: @account.id, phone_number: phone_number)
  end

  def participant_lid_contact(bsuid)
    contact = Contact.find_by(account_id: @account.id, bsuid: bsuid)
    contact_from_inbox = @inbox.contact_inboxes.find_by(source_id: bsuid)&.contact

    return contact_from_inbox if contact_from_inbox.present? && contact_from_inbox.id != contact&.id

    contact || contact_from_inbox
  end

  def participant_phone_number(participant, source_id)
    return if source_id.to_s.include?('@') && participant[:wa_id].blank?

    phone = normalized_phone((participant[:wa_id].presence || source_id).to_s.gsub(/\D/, ''))
    "+#{phone}" if phone.present?
  end

  def compatible_group_phone_contact(participant)
    return if @conversation.blank?

    participant_name = participant_name(participant)
    return if participant_name.blank?

    candidates = @conversation.group_contacts.includes(:contact).filter_map(&:contact).select do |contact|
      contact.phone_number.present? && contact.bsuid.blank? && compatible_name?(participant_name, contact.name)
    end.uniq

    candidates.one? ? candidates.first : nil
  end

  def participant_name(participant)
    participant[:name].presence || participant[:pushname].presence || participant[:username].presence
  end

  def compatible_name?(left, right)
    left = normalize_name(left)
    right = normalize_name(right)
    return false if left.blank? || right.blank?
    return true if left == right

    shorter, longer = [left, right].sort_by(&:length)
    return false if shorter.length < 5

    longer.start_with?(shorter) || longer.end_with?(shorter) || longer.include?(shorter)
  end

  def normalize_name(value)
    I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]/, '')
  end

  def lid_contact_attributes(phone_contact, lid_contact, participant)
    {
      bsuid: phone_contact.bsuid.presence || lid_contact.bsuid.presence || participant_bsuid(participant),
      whatsapp_username: phone_contact.whatsapp_username.presence || lid_contact.whatsapp_username
    }.compact
  end

  def merge_lid_contact_attributes(phone_contact, attrs)
    return if attrs.blank?

    phone_contact.reload
    attrs = {
      bsuid: phone_contact.bsuid.presence || attrs[:bsuid],
      whatsapp_username: phone_contact.whatsapp_username.presence || attrs[:whatsapp_username]
    }.compact
    phone_contact.update_columns(attrs.merge(updated_at: Time.current)) # rubocop:disable Rails/SkipsModelValidations
  end

  def merge_group_contacts(from_contact, to_contact)
    GroupContact.where(contact_id: from_contact.id).find_each do |group_contact|
      existing = GroupContact.find_by(conversation_id: group_contact.conversation_id, contact_id: to_contact.id)
      existing.present? ? merge_group_contact(group_contact, existing) : move_group_contact(group_contact, to_contact)
    end
  end

  def merge_group_contact(group_contact, existing)
    metadata = (existing.metadata || {}).merge(group_contact.metadata || {})
    existing.update_columns(metadata: metadata, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    group_contact.destroy!
  end

  def move_group_contact(group_contact, contact)
    group_contact.update_columns(contact_id: contact.id, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def sanitize_contact_email(contact)
    return if contact.email.blank? || valid_contact_email?(contact.email)

    Rails.logger.info("[WHATSAPP][GROUP] clearing invalid participant email contact_id=#{contact.id} email=#{contact.email}")
    contact.update_columns(email: nil, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def valid_contact_email?(email)
    email.match?(Devise.email_regexp) || email.end_with?('@lid') || email.end_with?('@g.us')
  end

  def participant_bsuid(participant)
    participant[:user_id].presence || participant[:lid].presence
  end

  def normalized_phone(phone)
    return phone unless phone.start_with?('55') && phone.length == 12

    "#{phone[0..3]}9#{phone[4..]}"
  end
end
