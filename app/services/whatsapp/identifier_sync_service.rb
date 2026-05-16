class Whatsapp::IdentifierSyncService
  pattr_initialize [:contact_inbox!, :contact]

  def perform(source_ids: [], username: nil)
    create_contact_inboxes(source_ids)
    update_contact(username)
  end

  private

  def create_contact_inboxes(source_ids)
    source_ids.compact_blank.uniq.each do |source_id|
      next if inbox.contact_inboxes.exists?(source_id: source_id)

      ContactInboxBuilder.new(contact: synced_contact, inbox: inbox, source_id: source_id).perform
    end
  end

  def update_contact(username)
    return if synced_contact.blank?

    username = normalize_username(username)
    return if username.blank?

    synced_contact.update!(additional_attributes: additional_attributes_with_username(username))
  end

  def synced_contact
    @synced_contact ||= contact || contact_inbox.contact
  end

  def inbox
    @inbox ||= contact_inbox.inbox
  end

  def normalize_username(value)
    value.to_s.sub(/\A@+/, '').presence
  end

  def additional_attributes_with_username(username)
    attributes = synced_contact.additional_attributes.deep_dup
    social_profiles = attributes['social_profiles'] || {}
    social_profiles['whatsapp'] = username

    attributes.merge(
      'social_profiles' => social_profiles,
      'social_whatsapp_user_name' => username
    )
  end
end
