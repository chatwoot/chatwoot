# WhatsApp regenerates a user's business scoped user id when that user changes
# their phone number, and reports it through the `user_id_update` webhook, which
# carries both the previous and the current identifier. Re-point the contact
# inbox so the existing contact and its history are kept, instead of the next
# message arriving as a brand new contact.
class Whatsapp::UserIdRotationService
  pattr_initialize [:inbox!, :payload!]

  def perform
    # The parent identifier is rotated first so that, when both change, the conversations end up
    # anchored to the regular one, which is the identifier that resolves the incoming messages.
    rotate(payload.dig(:parent_user_id, :previous), payload.dig(:parent_user_id, :current))
    rotate(payload.dig(:user_id, :previous), payload.dig(:user_id, :current))
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

    # One transaction, so a worker that dies midway leaves nothing half migrated: a retry
    # either finds the previous identifier and redoes the whole move, or finds the current
    # one and stops. A partial move would strand the conversations on the obsolete inbox
    # with no row left for the retry to recognise.
    ActiveRecord::Base.transaction do
      contact_inbox.update!(source_id: current_source_id)
      anchor_conversations(contact_inbox)
    end
  rescue ActiveRecord::RecordNotUnique
    # The row was created between the check above and the update. Nothing to do,
    # the identifier is already present in the inbox.
    Rails.logger.info("[WHATSAPP] source_id #{current_source_id} already taken in inbox #{inbox.id}")
  end

  # A conversation is anchored to whichever contact inbox resolved its first message, and
  # `Whatsapp::SendOnWhatsappService` replies through that source id. A contact that has both
  # identifiers is resolved by the phone one first, so replies would keep going to the number
  # the user just left. Anchor them to the business scoped user id instead, which is the
  # identifier that survived the change and which the Cloud API accepts as a `recipient`.
  def anchor_conversations(contact_inbox)
    contact_inbox.contact
                 .conversations
                 .where(inbox_id: inbox.id)
                 .where.not(contact_inbox_id: contact_inbox.id)
                 .find_each { |conversation| conversation.update!(contact_inbox: contact_inbox) }
  end
end
