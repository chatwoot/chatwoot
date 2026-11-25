# Handles consolidation of duplicate contact_inboxes for WhatsApp channels.
# This is needed because:
# 1. When a conversation is first created via UI, a contact_inbox is created with source_id = phone
# 2. When the contact responds, the contact_inbox is updated to source_id = LID
# 3. If the conversation is deleted/resolved and a new one is created, a new contact_inbox
#    with source_id = phone is created (since the existing one has LID)
# 4. This service consolidates these duplicates when a message arrives
#
# Phone lookups are ninth-digit-variant aware (Brazil/Argentina): a contact saved
# with the "wrong" variant (e.g. outbound on_whatsapp normalization was skipped)
# still matches the canonical number the webhook delivers, instead of spawning a
# duplicate contact and conversation. Exact matches always win over variants.
class Whatsapp::ContactInboxConsolidationService
  def initialize(inbox:, phone:, lid:, identifier:)
    @inbox = inbox
    @phone = phone
    @lid = lid
    @identifier = identifier
  end

  def perform # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return unless @phone.present? && @lid.present?
    # If phone and lid are the same, no consolidation needed
    return if @phone == @lid

    phone_contact_inbox = find_phone_contact_inbox
    lid_contact_inbox = find_lid_contact_inbox

    if phone_contact_inbox && lid_contact_inbox
      if should_consolidate?(phone_contact_inbox, lid_contact_inbox)
        consolidate_contact_inboxes(phone_contact_inbox, lid_contact_inbox)
      else
        consolidate_different_contacts(phone_contact_inbox, lid_contact_inbox)
      end
    elsif phone_contact_inbox
      migrate_phone_to_lid(phone_contact_inbox)
    elsif phone_contact_inbox.nil?
      # No phone-based contact_inbox exists, try to find contact by phone and update their contact_inbox
      update_existing_contact_inbox_by_phone
    end
  end

  private

  def find_phone_contact_inbox
    @inbox.contact_inboxes.find_by(source_id: @phone) ||
      (@inbox.contact_inboxes.find_by(source_id: alternate_phone_variants) if alternate_phone_variants.any?)
  end

  def find_lid_contact_inbox
    @inbox.contact_inboxes.find_by(source_id: @lid)
  end

  def should_consolidate?(phone_contact_inbox, lid_contact_inbox)
    phone_contact_inbox.contact_id == lid_contact_inbox.contact_id
  end

  def consolidate_contact_inboxes(phone_contact_inbox, lid_contact_inbox)
    ActiveRecord::Base.transaction do
      phone_contact_inbox.conversations.find_each do |conversation|
        conversation.update!(contact_inbox_id: lid_contact_inbox.id)
      end

      phone_contact_inbox.destroy!
    end
  end

  # Handles the case where phone and LID contact_inboxes belong to different contacts.
  # The phone contact is treated as canonical (has real user data like name and phone_number).
  # Merges by moving LID conversations to the phone contact and consolidating into a single contact_inbox.
  def consolidate_different_contacts(phone_contact_inbox, lid_contact_inbox)
    phone_contact = phone_contact_inbox.contact
    lid_contact = lid_contact_inbox.contact

    ActiveRecord::Base.transaction do
      moved_conversation_ids = lid_contact_inbox.conversations.pluck(:id)
      lid_contact.update!(phone_number: nil) if lid_contact.phone_number == "+#{@phone}"

      # Move conversations from LID contact_inbox to the phone contact
      lid_contact_inbox.conversations.find_each do |conversation|
        conversation.update!(contact_inbox_id: phone_contact_inbox.id, contact_id: phone_contact.id)
      end

      lid_contact_inbox.destroy!
      reassign_sender_and_destroy(lid_contact, phone_contact, conversation_ids: moved_conversation_ids)

      # Resolve identifier conflicts account-wide, then update the canonical contact
      transfer_identifier_to(phone_contact)
      phone_contact_inbox.update!(source_id: @lid)
      phone_contact.update!(identifier: @identifier, phone_number: "+#{@phone}")
    end
  end

  def migrate_phone_to_lid(phone_contact_inbox)
    existing_contact = phone_contact_inbox.contact

    return if phone_conflict?(existing_contact)

    ActiveRecord::Base.transaction do
      transfer_identifier_to(existing_contact)
      phone_contact_inbox.update!(source_id: @lid)
      existing_contact.update!(identifier: @identifier, phone_number: "+#{@phone}")
    end
  end

  # Find contact by phone number and update their contact_inbox source_id to LID
  # This handles the case where contact_inbox has a different source_id (e.g., old format)
  def update_existing_contact_inbox_by_phone
    existing_contact = find_contact_by_phone_variants
    return unless existing_contact

    existing_contact_inbox = existing_contact.contact_inboxes.find_by(inbox_id: @inbox.id)

    unless existing_contact_inbox
      # Contact exists by phone but has no contact_inbox in this inbox (e.g., after provider conversion).
      # Must still resolve identifier conflicts so the builder finds the phone-based contact
      # instead of a stale LID-only contact, which would cause "Phone number has already been taken".
      adopt_or_resolve_lid_contact(existing_contact)
      return
    end

    # If a LID contact_inbox already exists, route into the merge logic instead of early-returning
    lid_contact_inbox = find_lid_contact_inbox
    if lid_contact_inbox
      return if lid_contact_inbox.contact_id == existing_contact.id

      return consolidate_different_contacts(existing_contact_inbox, lid_contact_inbox)
    end
    ActiveRecord::Base.transaction do
      transfer_identifier_to(existing_contact)
      existing_contact.update!(identifier: @identifier)
      existing_contact_inbox.update!(source_id: @lid)
    end
  end

  # When the phone-based contact has no contact_inbox in this inbox, handle
  # any conflicting LID contact that would otherwise intercept the builder lookup.
  def adopt_or_resolve_lid_contact(phone_contact)
    lid_contact_inbox = find_lid_contact_inbox

    if lid_contact_inbox && lid_contact_inbox.contact_id != phone_contact.id
      adopt_lid_contact_inbox(phone_contact, lid_contact_inbox)
    else
      transfer_identifier_to(phone_contact)
    end
  end

  # Transfer a LID contact_inbox (and its conversations) from the LID contact to the phone contact.
  def adopt_lid_contact_inbox(phone_contact, lid_ci)
    lid_contact = lid_ci.contact

    ActiveRecord::Base.transaction do
      moved_conversation_ids = lid_ci.conversations.pluck(:id)
      lid_contact.update!(phone_number: nil) if lid_contact.phone_number == "+#{@phone}"

      lid_ci.conversations.find_each do |conversation|
        conversation.update!(contact_id: phone_contact.id)
      end
      lid_ci.update!(contact_id: phone_contact.id)

      # Resolve identifier conflicts account-wide, not just with lid_contact
      transfer_identifier_to(phone_contact)
      phone_contact.update!(identifier: @identifier)

      reassign_sender_and_destroy(lid_contact, phone_contact, conversation_ids: moved_conversation_ids)
    end
  end

  def find_contact_by_phone_variants
    contacts = @inbox.account.contacts
    contacts.find_by(phone_number: "+#{@phone}") ||
      (contacts.find_by(phone_number: alternate_phone_variants.map { |variant| "+#{variant}" }) if alternate_phone_variants.any?)
  end

  # The other ninth-digit forms @phone may be stored under (Brazil/Argentina).
  def alternate_phone_variants
    @alternate_phone_variants ||= begin
      normalizer = Whatsapp::PhoneNumberNormalizationService::NORMALIZERS
                   .map(&:new)
                   .find { |candidate| candidate.handles_country?(@phone) }
      normalizer ? normalizer.variants(@phone) - [@phone] : []
    end
  end

  # Resolve identifier conflict by transferring the identifier to the phone-based contact.
  def transfer_identifier_to(target_contact)
    return if target_contact.identifier == @identifier

    conflicting = @inbox.account.contacts.find_by(identifier: @identifier)
    return unless conflicting && conflicting.id != target_contact.id

    ActiveRecord::Base.transaction do
      conflicting.update!(identifier: nil)
      target_contact.update!(identifier: @identifier)
    end
  end

  def identifier_conflict?(existing_contact)
    conflicting = @inbox.account.contacts.find_by(identifier: @identifier)
    conflicting.present? && conflicting.id != existing_contact.id
  end

  def phone_conflict?(existing_contact)
    conflicting = @inbox.account.contacts.find_by(phone_number: "+#{@phone}")
    conflicting.present? && conflicting.id != existing_contact.id
  end

  # Reassign message sender references for moved conversations, then destroy source contact if orphaned.
  # Scoped to conversation_ids to avoid touching messages in other inboxes the source contact may still own.
  # Prevents dependent: :destroy_async on Contact#messages from deleting message history.
  def reassign_sender_and_destroy(source_contact, target_contact, conversation_ids:)
    Message.where(sender: source_contact, conversation_id: conversation_ids)
           .update_all(sender_id: target_contact.id) # rubocop:disable Rails/SkipsModelValidations
    source_contact.destroy! if source_contact.contact_inboxes.reload.empty?
  end
end
