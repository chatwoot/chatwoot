class Whatsapp::IdentifierSyncService
  pattr_initialize [:contact_inbox!, :contact]

  def perform(source_ids: [], username: nil, phone_number: nil)
    create_contact_inboxes(source_ids)
    update_contact(source_ids, username, phone_number)
  end

  private

  def create_contact_inboxes(source_ids)
    source_ids.compact_blank.uniq.each do |source_id|
      next if inbox.contact_inboxes.exists?(source_id: source_id)

      inbox.contact_inboxes.create!(contact: synced_contact, source_id: source_id)
    rescue ActiveRecord::RecordNotUnique
      # A concurrent webhook (e.g. a status update bypassing the per-contact
      # mutex) just inserted the same (inbox_id, source_id). Treat it as a
      # no-op instead of falling through to ContactInboxBuilder's retry path,
      # which would scramble the freshly-written row.
    end
  end

  def update_contact(source_ids, username, phone_number)
    return if synced_contact.blank?

    update_contact_phone_number(phone_number)
    update_contact_username(username)
    update_contact_bsuid(source_ids)
  end

  def update_contact_phone_number(phone_number)
    phone_number = phone_number.presence
    return if phone_number.blank? || synced_contact.phone_number.present?
    return if synced_contact.account.contacts.where(phone_number: phone_number).where.not(id: synced_contact.id).exists?

    synced_contact.update!(phone_number: phone_number)
  end

  def update_contact_username(username)
    username = normalize_username(username)
    return if username.blank?

    synced_contact.update!(additional_attributes: additional_attributes_with_username(username))
  end

  # The phone number and the username are already mirrored onto the contact above, which is
  # what makes them reachable to everything that reads a contact: the agent bot webhook, the
  # websocket payload and the REST API. The business scoped user id is the third WhatsApp
  # identity and the only one that stays confined to `contact_inbox.source_id`, where a
  # payload only ever surfaces the single source id the conversation happens to be anchored
  # to, usually the phone one. Mirror it as well so integrations can resolve the contact
  # without a follow-up request.
  def update_contact_bsuid(source_ids)
    bsuids = source_ids.filter_map { |source_id| whatsapp_bsuid(source_id) }
    return if bsuids.blank?

    attributes = synced_contact.additional_attributes.deep_dup.merge(bsuid_attributes(bsuids))
    return if attributes == synced_contact.additional_attributes

    synced_contact.update!(additional_attributes: attributes)
  end

  # Twilio prefixes its source ids with the channel name, so the identifier is matched and
  # reported without it, in the bare form the Cloud API and the Meta payloads use.
  def whatsapp_bsuid(source_id)
    identifier = source_id.to_s.delete_prefix('whatsapp:')
    identifier if identifier.match?(RegexHelper::WHATSAPP_BSUID_REGEX)
  end

  # A parent identifier carries the `ENT` segment and groups a user across the business
  # portfolios, so it is reported next to the regular one rather than replacing it. It only
  # stands in for the regular key while nothing is mirrored there yet: a payload that carries
  # the parent alone, such as a status update, must not downgrade an identifier already known.
  def bsuid_attributes(bsuids)
    parent, regular = bsuids.partition { |bsuid| bsuid.to_s.include?('.ENT.') }
    identifier = regular.first || mirrored_bsuid || parent.first
    attributes = {}
    attributes['whatsapp_bsuid'] = identifier if identifier.present?
    attributes['whatsapp_bsuid_parent'] = parent.first if parent.first.present?
    attributes
  end

  def mirrored_bsuid
    synced_contact.additional_attributes['whatsapp_bsuid'].presence
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
