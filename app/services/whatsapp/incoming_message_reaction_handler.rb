module Whatsapp::IncomingMessageReactionHandler
  # WhatsApp reactions target a message we may or may not have. We resolve the target
  # message BEFORE touching contact resolution so that a reaction to a message we don't
  # have never creates a Contact/ContactInbox as a side effect. We never create a
  # Conversation or Message for a reaction -- we only ever upsert a MessageReaction
  # against the existing target message/conversation.
  def process_reaction_message(message)
    return unless Whatsapp::MessageDedupLock.new(message[:id]).acquire!

    reaction_payload = message[:reaction]
    # WhatsApp's wamid is platform-globally-unique, but we scope the lookup to this inbox
    # anyway to stay consistent with the other channels and not rely solely on that external
    # provider invariant.
    target_message = inbox.messages.find_by(source_id: reaction_payload[:message_id])
    return log_missing_reaction_target(reaction_payload) if target_message.blank?

    set_contact
    return if @contact.blank?

    upsert_reaction(message, reaction_payload, target_message)
  end

  def log_missing_reaction_target(reaction_payload)
    Rails.logger.warn "Whatsapp Error: reaction target message not found - source_id: #{reaction_payload[:message_id]}"
  end

  def upsert_reaction(message, reaction_payload, target_message)
    emoji = reaction_payload[:emoji]

    Messages::Reactions::UpsertService.new(
      account: target_message.account,
      inbox: target_message.inbox,
      conversation: target_message.conversation,
      message: target_message,
      sender: @contact,
      actor_external_id: message[:from].to_s,
      source_id: message[:id],
      external_message_id: reaction_payload[:message_id],
      emoji: emoji,
      reaction_type: emoji.present? ? 'emoji' : nil,
      action: emoji.present? ? :react : :unreact,
      external_created_at: Time.zone.at(message[:timestamp].to_i)
    ).perform
  end
end
