# WhatsApp regenerates a user's business scoped user id when that user changes their phone
# number, and reports it through the `user_id_update` webhook, which names both the previous
# and the current identifier. Recording the current one as another alias of the same contact
# keeps that person's history instead of letting the next message arrive as a new contact.
#
# Nothing is renamed and nothing is moved. The previous identifier stays on the contact, so a
# delayed event that still carries it resolves to the same person, and conversations opened
# under it stay where they are and remain reachable under previous conversations. Messages that
# arrive after the rotation resolve through the exact new identifier.
class Whatsapp::UserIdRotationService
  # The holder of the mutex is processing a message for the identifier being introduced, so it
  # is worth a short wait rather than racing it into a split contact.
  LOCK_ATTEMPTS = 3
  LOCK_RETRY_INTERVAL = 0.2
  LOCK_TTL = 30.seconds

  pattr_initialize [:inbox!, :updates!]

  def perform
    updates.each do |update|
      rotations(update).each { |previous_source_id, current_source_id| rotate(previous_source_id, current_source_id) }
    end
  end

  private

  # The parent identifier first, so that an event carrying both leaves the rows in the same
  # order the inbound path appends them.
  def rotations(update)
    [
      [update.dig(:parent_user_id, :previous), update.dig(:parent_user_id, :current)],
      [update.dig(:user_id, :previous), update.dig(:user_id, :current)]
    ].select { |previous, current| previous.present? && current.present? && previous != current }
  end

  # Serialized on the identifier being introduced, because the event races the first message
  # that arrives under it: that message finds no row for the new identifier and builds a second
  # contact for someone we already know. The job level mutex cannot cover this on its own. It
  # locks a single sender id, while one payload can carry several rotations and one rotation can
  # name both a regular and a parent identifier, so every identifier past the first is unguarded.
  #
  # Acquiring the lock is best effort. Holding it is what prevents the split, but failing to get
  # it is not a reason to drop the alias, since the write itself is safe either way and skipping
  # would lose the rotation for good.
  def rotate(previous_source_id, current_source_id)
    return record_alias(previous_source_id, current_source_id) if current_source_id == job_locked_source_id

    key = format(::Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: inbox.id, sender_id: current_source_id)
    lock_manager = Redis::LockManager.new

    LOCK_ATTEMPTS.times do
      return if lock_manager.with_lock(key, LOCK_TTL) { record_alias(previous_source_id, current_source_id) }

      sleep(LOCK_RETRY_INTERVAL)
    end

    # The holder is still working. Dropping the rotation would lose it for good, so the alias is
    # recorded anyway and `record_alias` reports a landing on another contact instead of hiding it.
    record_alias(previous_source_id, current_source_id)
  end

  # `Webhooks::WhatsappEventsJob` already holds the mutex for one identifier, derived from the
  # FIRST entry of the batch. Taking that one again here would block on our own lock, and deriving
  # it per entry would silently skip the lock for every entry after the first, which is exactly the
  # case the job does not cover. Mirrors `contact_sender_id_from_user_id_update`.
  def job_locked_source_id
    @job_locked_source_id ||= begin
      first = updates.first || {}
      [first.dig(:parent_user_id, :current), first.dig(:user_id, :current), first[:wa_id]].compact_blank.first
    end
  end

  def record_alias(previous_source_id, current_source_id)
    contact_inbox = inbox.contact_inboxes.find_by(source_id: previous_source_id)
    # The previous identifier is unknown, so there is no history to keep and nothing to attach
    # the current one to. A later message carrying it creates the contact in the usual way.
    return if contact_inbox.blank?

    existing = inbox.contact_inboxes.find_by(source_id: current_source_id)
    return log_collision(existing, contact_inbox, current_source_id) if existing.present?

    inbox.contact_inboxes.create!(contact: contact_inbox.contact, source_id: current_source_id)
  rescue ActiveRecord::RecordNotUnique
    # Someone inserted the same (inbox_id, source_id) while this was running, which is only
    # harmless when it landed on the same contact. A message that arrived under the current
    # identifier before this event builds a contact of its own, and treating that as done would
    # leave the two identifiers on different contacts with nothing said about it.
    log_collision(inbox.contact_inboxes.find_by(source_id: current_source_id), contact_inbox, current_source_id)
  end

  # Already known. On the same contact the rotation is simply already recorded, most often
  # because a duplicate or out of order event arrived. On another contact the two identities
  # would have to be merged, which is a separate concern with its own failure modes, so both
  # rows are left exactly as they are.
  def log_collision(existing, contact_inbox, current_source_id)
    return if existing.blank?
    return if existing.contact_id == contact_inbox.contact_id

    Rails.logger.warn(
      "[WHATSAPP] user_id_update: #{current_source_id} already belongs to contact #{existing.contact_id} " \
      "in inbox #{inbox.id}, not moving it from contact #{contact_inbox.contact_id}"
    )
  end
end
