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
  pattr_initialize [:inbox!, :payload!]

  def perform
    rotations.each { |previous_source_id, current_source_id| rotate(previous_source_id, current_source_id) }
  end

  private

  # The parent identifier first, so that an event carrying both leaves the rows in the same
  # order the inbound path appends them.
  def rotations
    [
      [payload.dig(:parent_user_id, :previous), payload.dig(:parent_user_id, :current)],
      [payload.dig(:user_id, :previous), payload.dig(:user_id, :current)]
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
    return if Redis::LockManager.new.with_lock(key, 30.seconds) { record_alias(previous_source_id, current_source_id) }

    record_alias(previous_source_id, current_source_id)
  end

  # `Webhooks::WhatsappEventsJob` already holds the mutex for one identifier of this payload.
  # Taking it again here would deadlock against our own lock, so that one is used as is.
  def job_locked_source_id
    @job_locked_source_id ||= [
      payload.dig(:parent_user_id, :current),
      payload.dig(:user_id, :current),
      payload[:wa_id]
    ].compact_blank.first
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
    # A concurrent webhook inserted the same (inbox_id, source_id) first. The alias exists,
    # which is the whole point, so there is nothing left to do.
    nil
  end

  # Already known. On the same contact the rotation is simply already recorded, most often
  # because a duplicate or out of order event arrived. On another contact the two identities
  # would have to be merged, which is a separate concern with its own failure modes, so both
  # rows are left exactly as they are.
  def log_collision(existing, contact_inbox, current_source_id)
    return if existing.contact_id == contact_inbox.contact_id

    Rails.logger.warn(
      "[WHATSAPP] user_id_update: #{current_source_id} already belongs to contact #{existing.contact_id} " \
      "in inbox #{inbox.id}, not moving it from contact #{contact_inbox.contact_id}"
    )
  end
end
