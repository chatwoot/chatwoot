class ContactInboxSourceIdResolver
  pattr_initialize [:inbox!, :source_ids!, :contact_attributes!, { prefer_first_source_id: false }]

  def perform
    existing = existing_contact_inbox
    return create_contact_inbox if existing.blank?
    return existing unless prefer_first_source_id
    return existing if existing.source_id == preferred_source_id

    adopt_preferred_source_id(existing)
  end

  private

  # Opt in, because most callers want the opposite: reuse whichever alias already exists. A
  # caller that asks for this is saying the first identifier is the identity a payload should
  # land on, so finding a different row means the contact reached this inbox under an older
  # identity and the preferred one has no row yet. It is created here, on that same contact,
  # rather than deferring to the identifier sync that runs later: without it the first payload
  # carrying the new identity would resolve to the old row and only the next one would move.
  #
  # The insert runs in a savepoint because inbound calls resolve identity inside an outer
  # transaction: on PostgreSQL a unique violation aborts the enclosing transaction, so without
  # one the rescue below would raise on its own lookup instead of recovering.
  def adopt_preferred_source_id(existing)
    ActiveRecord::Base.transaction(requires_new: true) do
      inbox.contact_inboxes.create!(contact: existing.contact, source_id: preferred_source_id)
    end
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
