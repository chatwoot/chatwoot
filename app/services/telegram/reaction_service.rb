# https://core.telegram.org/bots/api#messagereactionupdated
#
# Telegram reactions target a message we may or may not have. We resolve the target
# message BEFORE touching contact resolution so that a reaction to a message we don't
# have never creates a Contact/ContactInbox as a side effect. We never create a
# Conversation or Message for a reaction -- we only ever upsert a MessageReaction
# against the existing target message/conversation.
class Telegram::ReactionService
  pattr_initialize [:inbox!, :params!]

  SUPPORTED_REACTION_TYPE = 'emoji'.freeze

  def perform
    return log_missing_target if target_message.blank?
    return log_unsupported_reaction_type if unsupported_reaction_type?

    set_contact
    upsert_reaction
  end

  private

  def message_reaction
    @message_reaction ||= params[:message_reaction]
  end

  # Telegram's message_id is only unique within a single chat/bot, not globally, so the lookup
  # must be scoped to this inbox -- otherwise a reaction could resolve to another tenant's
  # message that happens to share the same message_id.
  def target_message
    @target_message ||= inbox.messages.find_by(source_id: message_reaction[:message_id].to_s)
  end

  def new_reaction
    @new_reaction ||= message_reaction[:new_reaction].presence || []
  end

  def action
    new_reaction.blank? ? :unreact : :react
  end

  def reaction_type
    return nil if action == :unreact

    new_reaction.first[:type]
  end

  def emoji
    return nil if action == :unreact

    new_reaction.first[:emoji]
  end

  def unsupported_reaction_type?
    action == :react && reaction_type != SUPPORTED_REACTION_TYPE
  end

  def actor
    @actor ||= message_reaction[:user] || message_reaction[:actor_chat]
  end

  def actor_id
    actor[:id]
  end

  def actor_name
    return "#{actor[:first_name]} #{actor[:last_name]}".strip if actor[:first_name].present?

    actor[:title]
  end

  def contact_attributes
    {
      name: actor_name,
      additional_attributes: {
        username: actor[:username],
        language_code: actor[:language_code],
        social_telegram_user_id: actor_id
      }
    }
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: actor_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact = contact_inbox.contact
  end

  # Telegram's update_id is only unique within a single bot's update stream, not globally --
  # two different Telegram channels can emit the same update_id. Scope it by inbox so it stays
  # globally unique (MessageReaction#source_id has a global uniqueness constraint) while still
  # deduping redelivery of the same bot event.
  def source_id
    "#{inbox.id}:#{params[:update_id]}"
  end

  def upsert_reaction
    Messages::Reactions::UpsertService.new(
      account: target_message.account,
      inbox: target_message.inbox,
      conversation: target_message.conversation,
      message: target_message,
      sender: @contact,
      actor_external_id: actor_id.to_s,
      source_id: source_id,
      external_message_id: message_reaction[:message_id].to_s,
      emoji: emoji,
      reaction_type: reaction_type,
      action: action,
      external_created_at: Time.zone.at(message_reaction[:date].to_i)
    ).perform
  end

  def log_missing_target
    Rails.logger.warn "Telegram Error: reaction target message not found - source_id: #{message_reaction[:message_id]}"
  end

  def log_unsupported_reaction_type
    Rails.logger.warn "Telegram Error: unsupported reaction type - #{reaction_type}"
  end
end
