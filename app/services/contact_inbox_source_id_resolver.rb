class ContactInboxSourceIdResolver
  pattr_initialize [:inbox!, :source_ids!, :contact_attributes!]

  def perform
    existing_contact_inbox || create_contact_inbox
  end

  private

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
