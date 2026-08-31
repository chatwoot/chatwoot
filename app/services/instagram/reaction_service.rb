class Instagram::ReactionService
  pattr_initialize [:params!, :channel!]

  def perform
    return log_missing_target if target_message.blank?

    set_contact
    upsert_reaction
  end

  private

  def reaction
    @reaction ||= params[:reaction]
  end

  def target_message
    @target_message ||= channel.inbox.messages.find_by(source_id: reaction[:mid])
  end

  def actor_id
    params[:sender][:id]
  end

  def action
    reaction[:action].to_sym
  end

  def emoji
    return nil if action == :unreact

    reaction[:emoji]
  end

  def reaction_type
    return nil if action == :unreact

    reaction[:reaction]
  end

  def set_contact
    contact_inbox = channel.inbox.contact_inboxes.find_by(source_id: actor_id)
    @contact = contact_inbox&.contact || channel.create_contact_inbox(actor_id, "Unknown (IG: #{actor_id})").contact
  end

  def upsert_reaction
    Messages::Reactions::UpsertService.new(
      account: target_message.account,
      inbox: target_message.inbox,
      conversation: target_message.conversation,
      message: target_message,
      sender: @contact,
      actor_external_id: actor_id,
      source_id: source_id,
      external_message_id: reaction[:mid],
      emoji: emoji,
      reaction_type: reaction_type,
      action: action,
      external_created_at: external_created_at
    ).perform
  end

  def source_id
    "#{reaction[:mid]}:#{actor_id}:#{params[:timestamp]}"
  end

  def external_created_at
    Time.zone.at(params[:timestamp].to_i / 1000)
  end

  def log_missing_target
    Rails.logger.warn "Instagram Error: reaction target message not found - source_id: #{reaction[:mid]}"
  end
end
