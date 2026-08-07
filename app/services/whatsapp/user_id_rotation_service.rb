# WhatsApp regenerates a user's business scoped user id when that user changes
# their phone number, and reports it through the `user_id_update` webhook, which
# carries both the previous and the current identifier. Re-point the contact
# inbox so the existing contact and its history are kept, instead of the next
# message arriving as a brand new contact.
class Whatsapp::UserIdRotationService
  pattr_initialize [:inbox!, :payload!]

  def perform
    rotate(payload.dig(:user_id, :previous), payload.dig(:user_id, :current))
    rotate(payload.dig(:parent_user_id, :previous), payload.dig(:parent_user_id, :current))
  end

  private

  def rotate(previous_source_id, current_source_id)
    return if previous_source_id.blank? || current_source_id.blank?
    return if previous_source_id == current_source_id

    contact_inbox = inbox.contact_inboxes.find_by(source_id: previous_source_id)
    return if contact_inbox.blank?
    # The current identifier already belongs to a contact inbox, so the update was
    # either replayed or the user reached us through it in the meantime. Merging
    # the two contact inboxes is a separate concern.
    return if inbox.contact_inboxes.exists?(source_id: current_source_id)

    contact_inbox.update!(source_id: current_source_id)
  rescue ActiveRecord::RecordNotUnique
    # The row was created between the check above and the update. Nothing to do,
    # the identifier is already present in the inbox.
    Rails.logger.info("[WHATSAPP] source_id #{current_source_id} already taken in inbox #{inbox.id}")
  end
end
