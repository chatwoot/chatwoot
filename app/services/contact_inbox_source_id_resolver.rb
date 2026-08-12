class ContactInboxSourceIdResolver
  pattr_initialize [:inbox!, :source_ids!, :contact_attributes!]

  def perform
    existing = existing_contact_inbox
    return create_contact_inbox if existing.blank?
    return existing if existing.source_id == preferred_source_id

    adopt_preferred_source_id(existing)
  end

  private

  # The caller lists the identifiers in the order it wants them resolved, so the first one is
  # the identity a payload should land on. Finding a different row means the contact reached
  # this inbox under an older identity and the preferred one has no row yet: it is created
  # here, on that same contact, rather than deferring to the identifier sync that runs later.
  # Without this the first payload carrying the new identity would still resolve to the old
  # row, and only the one after it would move, which splits the thread a message too late.
  def adopt_preferred_source_id(existing)
    inbox.contact_inboxes.create!(contact: existing.contact, source_id: preferred_source_id)
  rescue ActiveRecord::RecordNotUnique
    inbox.contact_inboxes.find_by(source_id: preferred_source_id) || existing
  end

  def preferred_source_id
    normalized_source_ids.first
  end

  def existing_contact_inbox
    normalized_source_ids.each do |source_id|
      contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
      return contact_inbox if contact_inbox
    end

    nil
  end

  def create_contact_inbox
    ::ContactInboxWithContactBuilder.new(
      source_id: normalized_source_ids.first,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform
  end

  def normalized_source_ids
    @normalized_source_ids ||= source_ids.compact_blank.uniq
  end
end
