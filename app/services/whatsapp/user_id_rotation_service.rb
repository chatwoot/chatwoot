# Meta reports BSUID rotation on the existing `messages` webhook subscription. The payload is a
# system message of type `user_changed_user_id` or `user_changed_number`; its typed `system`
# properties carry the previous and current identifiers. The human-readable body is not parsed.
#
# New identifiers are recorded as aliases of the existing contact. Previous aliases and the
# conversations opened under them stay untouched, so delayed webhooks still resolve safely and
# conversation routing remains scoped to the exact ContactInbox selected by future events.
class Whatsapp::UserIdRotationService
  SUPPORTED_SYSTEM_TYPES = %w[user_changed_number user_changed_user_id].freeze
  LOCK_ATTEMPTS = 3
  LOCK_RETRY_INTERVAL = 0.2
  LOCK_TTL = 30.seconds

  pattr_initialize [:inbox!, :messages!, { job_locked_source_id: nil }]

  def perform
    messages.each do |message|
      system = message[:system] || {}
      next unless SUPPORTED_SYSTEM_TYPES.include?(system[:type])

      process_system_message(system)
    end
  end

  private

  def process_system_message(system)
    rotations = rotations(system)
    raw_phone_source_id = raw_whatsapp_phone_source_id(system[:wa_id]) if system[:type] == 'user_changed_number'
    phone_source_id = normalized_whatsapp_phone_source_id(raw_phone_source_id) if raw_phone_source_id.present?
    rotated_source_ids = rotations.map(&:last)
    current_source_ids = [*rotated_source_ids, phone_source_id].compact_blank.uniq

    with_rotation_locks(current_source_ids) do
      contact = resolve_contact(rotations, current_source_ids)
      next if contact.blank?

      record_aliases(contact, rotated_source_ids)
      record_phone_identity(contact, phone_source_id, raw_phone_source_id) if phone_source_id.present?
    end
  end

  # Parent first keeps lifecycle lock ordering aligned with BSUID-only Cloud payloads.
  def rotations(system)
    [
      [system[:previous_parent_user_id], system[:parent_user_id]],
      [system[:previous_user_id], system[:user_id]]
    ].select { |previous, current| previous.present? && current.present? && previous != current }
  end

  # Resolve through previous identifiers first. Current identifiers are only a fallback for a
  # replay or for the case where a normal message reached Chatwoot before the lifecycle event.
  # Conflicting identifiers must remain reviewable; they are never merged automatically.
  def resolve_contact(rotations, current_source_ids)
    previous_source_ids = rotations.map(&:first)
    contact = single_contact_for(previous_source_ids, 'previous')
    return contact if contact.present?
    return if previous_source_ids.any? { |source_id| inbox.contact_inboxes.exists?(source_id: source_id) }

    single_contact_for(current_source_ids, 'current')
  end

  def single_contact_for(source_ids, identifier_set)
    contact_ids = inbox.contact_inboxes.where(source_id: source_ids).distinct.pluck(:contact_id)
    return if contact_ids.blank?
    return inbox.account.contacts.find(contact_ids.first) if contact_ids.one?

    Rails.logger.warn(
      "[WHATSAPP] identity rotation: #{identifier_set} identifiers belong to multiple contacts " \
      "#{contact_ids.join(', ')} in inbox #{inbox.id}"
    )
    nil
  end

  def record_aliases(contact, source_ids)
    source_ids.each do |source_id|
      existing = inbox.contact_inboxes.find_by(source_id: source_id)
      next if existing&.contact_id == contact.id

      if existing.present?
        log_alias_collision(existing, contact, source_id)
        next
      end

      inbox.contact_inboxes.create!(contact: contact, source_id: source_id)
    rescue ActiveRecord::RecordNotUnique
      log_alias_collision(inbox.contact_inboxes.find_by(source_id: source_id), contact, source_id)
    end
  end

  def record_phone_identity(contact, phone_source_id, raw_phone_source_id)
    phone_number = "+#{raw_phone_source_id}"
    previous_phone_number = contact.phone_number
    conflicting_contact = conflicting_phone_contact(contact, phone_number)
    if conflicting_contact.present?
      handle_phone_contact_collision(contact, conflicting_contact, phone_number)
      return
    end

    conflicting_contact_inbox = conflicting_phone_alias(contact, phone_source_id)
    if conflicting_contact_inbox.present?
      clear_stale_phone_number(contact)
      log_alias_collision(conflicting_contact_inbox, contact, phone_source_id)
      return
    end

    record_aliases(contact, [phone_source_id])
    return if contact.phone_number == phone_number

    contact.update!(phone_identity_attributes(contact, previous_phone_number, phone_number))
  end

  def phone_identity_attributes(contact, previous_phone_number, phone_number)
    attributes = { phone_number: phone_number }
    attributes[:name] = phone_number if auto_generated_phone_name?(contact.name, previous_phone_number)
    attributes
  end

  def auto_generated_phone_name?(name, phone_number)
    return false if name.blank? || phone_number.blank?

    normalized_phone_number = TelephoneNumber.parse(phone_number).international_number
    [phone_number, normalized_phone_number].compact_blank.uniq.include?(name)
  end

  def conflicting_phone_contact(contact, phone_number)
    contact.account.contacts.where(phone_number: phone_number).where.not(id: contact.id).first
  end

  def conflicting_phone_alias(contact, phone_source_id)
    inbox.contact_inboxes.where(source_id: phone_source_id).where.not(contact_id: contact.id).first
  end

  def handle_phone_contact_collision(contact, conflicting_contact, phone_number)
    clear_stale_phone_number(contact)
    Rails.logger.warn(
      "[WHATSAPP] identity rotation: #{phone_number} already belongs to contact #{conflicting_contact.id} " \
      "in account #{contact.account_id}; cleared the previous phone from contact #{contact.id}"
    )
  end

  def clear_stale_phone_number(contact)
    contact.update!(phone_number: nil) if contact.phone_number.present?
  end

  def raw_whatsapp_phone_source_id(value)
    value = value.to_s
    return unless value.match?(/\A[1-9]\d{1,14}\z/)

    value
  end

  def normalized_whatsapp_phone_source_id(value)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(value, :cloud)
  end

  # The job already holds the preferred current identifier. Keep every other current identifier
  # locked together while resolving and writing aliases so a concurrent inbound webhook cannot
  # create a second contact halfway through the rotation.
  def with_rotation_locks(source_ids, &)
    unlocked_source_ids = source_ids.reject { |source_id| source_id == job_locked_source_id }.sort
    acquire_locks(unlocked_source_ids, &)
  end

  def acquire_locks(source_ids, &)
    return yield if source_ids.empty?

    source_id = source_ids.first
    key = format(::Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: inbox.id, sender_id: source_id)
    lock_manager = Redis::LockManager.new

    LOCK_ATTEMPTS.times do
      acquired = lock_manager.with_lock(key, LOCK_TTL) { acquire_locks(source_ids.drop(1), &) }
      return if acquired

      sleep(LOCK_RETRY_INTERVAL)
    end

    raise MutexApplicationJob::LockAcquisitionError, "Failed to acquire WhatsApp identity rotation lock: #{key}"
  end

  def log_alias_collision(existing, contact, source_id)
    return if existing.blank? || existing.contact_id == contact.id

    Rails.logger.warn(
      "[WHATSAPP] identity rotation: #{source_id} already belongs to contact #{existing.contact_id} " \
      "in inbox #{inbox.id}, not attaching it to contact #{contact.id}"
    )
  end
end
