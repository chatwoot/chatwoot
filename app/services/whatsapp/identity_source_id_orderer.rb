class Whatsapp::IdentitySourceIdOrderer
  pattr_initialize [:inbox!, :phone_source_id, :source_ids!]

  def perform
    identifiers = source_ids.compact_blank
    default_order = [phone_source_id, *identifiers].compact_blank.uniq
    return default_order unless addressable_identifiers? && phone_source_id.present?
    return default_order if contact_inbox_has_conversations?(phone_source_id)

    existing_identifier = identifiers.find { |source_id| contact_inbox_has_conversations?(source_id) }
    return default_order if existing_identifier.blank?

    [existing_identifier, *(identifiers - [existing_identifier]), phone_source_id].compact_blank.uniq
  end

  private

  def addressable_identifiers?
    inbox.channel.try(:provider) == 'whatsapp_cloud'
  end

  def contact_inbox_has_conversations?(source_id)
    inbox.contact_inboxes.joins(:conversations).exists?(source_id: source_id)
  end
end
