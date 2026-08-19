class Whatsapp::IdentifierSyncService
  pattr_initialize [:contact_inbox!, :contact]

  def perform(source_ids: [], username: nil, phone_number: nil)
    create_contact_inboxes(source_ids)
    group_identifiers(source_ids)
    update_contact(username, phone_number)
  end

  private

  # The identifiers carried by one webhook are the only evidence Meta gives that two source ids
  # belong to the same person, and it gives it once, when the payload arrives. Recording it lets a
  # call site widen its scope to that evidence rather than to the whole contact, which is what
  # breaks once an agent merges two people in the dashboard.
  #
  # This never runs from a merge, only from an inbound payload, so rows an agent brought together
  # keep whatever groups they already had.
  def group_identifiers(source_ids)
    rows = identifier_rows(source_ids)
    return if rows.empty?

    groups = rows.filter_map(&:identity_group_id).uniq
    # Identifiers arriving together can prove that two existing groups are one person. Joining them
    # is a deliberate path rather than a side effect of a webhook, and it is the one place where
    # being wrong recreates the routing bug this exists to avoid, so this leaves them alone.
    return if groups.length > 1

    assign_identity_group(rows, groups.first || SecureRandom.uuid)
  end

  def assign_identity_group(rows, identity_group_id)
    ungrouped = rows.select { |row| row.identity_group_id.nil? }
    return if ungrouped.empty?

    # rubocop:disable Rails/SkipsModelValidations
    ContactInbox.where(id: ungrouped.map(&:id)).update_all(identity_group_id: identity_group_id, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def identifier_rows(source_ids)
    identifiers = source_ids.compact_blank.uniq
    return [] if identifiers.blank?

    inbox.contact_inboxes.where(source_id: identifiers).to_a
  end

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

  def update_contact(username, phone_number)
    return if synced_contact.blank?

    update_contact_phone_number(phone_number)
    update_contact_username(username)
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
