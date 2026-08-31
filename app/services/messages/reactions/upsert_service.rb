# Persists an inbound (or outbound) reaction event against a message, keeping it idempotent
# across two distinct scenarios:
#
# 1. The exact same provider webhook event (`source_id`) is redelivered -> reuse the same row.
# 2. The same actor reacts again to the same message with a different emoji (a new provider
#    event/`source_id`) -> update the existing row instead of inserting a second one, matched by
#    the logical identity (message, direction, external_message_id, actor_external_id).
class Messages::Reactions::UpsertService
  # rubocop:disable Metrics/ParameterLists
  def initialize(account:, inbox:, conversation:, message:, sender:, actor_external_id:, source_id:, external_message_id:,
                 action:, emoji: nil, reaction_type: nil, external_created_at: nil, metadata: {}, direction: :incoming)
    # rubocop:enable Metrics/ParameterLists
    @account = account
    @inbox = inbox
    @conversation = conversation
    @message = message
    @sender = sender
    @actor_external_id = actor_external_id
    @source_id = source_id
    @external_message_id = external_message_id
    @emoji = emoji
    @reaction_type = reaction_type
    @action = action.to_sym
    @external_created_at = external_created_at
    @metadata = metadata || {}
    @direction = direction
  end

  def perform
    return if message.blank?
    return unless target_message_valid?

    reaction = find_or_initialize_reaction
    was_new_record = reaction.new_record?
    previous_status = reaction.status
    previous_emoji = reaction.emoji
    previous_reaction_type = reaction.reaction_type

    assign_identity_attributes(reaction)
    assign_action_attributes(reaction)
    reaction.save!

    Messages::Reactions::ActivityService.new(
      reaction: reaction,
      was_new_record: was_new_record,
      previous_status: previous_status,
      previous_emoji: previous_emoji,
      previous_reaction_type: previous_reaction_type
    ).perform

    reaction
  end

  private

  attr_reader :account, :inbox, :conversation, :message, :sender, :actor_external_id, :source_id, :external_message_id,
              :emoji, :reaction_type, :action, :external_created_at, :metadata, :direction

  # The message passed in must actually belong to the account/conversation/inbox passed in.
  # A mismatch here means the caller resolved the wrong records (or is being handed stale/
  # cross-tenant data) -- we bail out quietly so a webhook job can log-and-continue.
  def target_message_valid?
    message.account_id == account.id && message.conversation_id == conversation.id && message.inbox_id == inbox.id
  end

  def find_or_initialize_reaction
    existing_by_source_id = source_id.present? ? MessageReaction.find_by(source_id: source_id) : nil
    return existing_by_source_id if existing_by_source_id

    if actor_external_id.present?
      MessageReaction.find_or_initialize_by(
        message_id: message.id,
        direction: direction,
        external_message_id: external_message_id,
        actor_external_id: actor_external_id
      )
    else
      MessageReaction.new(message: message, direction: direction, external_message_id: external_message_id)
    end
  end

  def assign_identity_attributes(reaction)
    reaction.account = account
    reaction.inbox = inbox
    reaction.conversation = conversation
    reaction.message = message
    reaction.sender = sender
    reaction.actor_external_id = actor_external_id
    reaction.external_message_id = external_message_id
    reaction.direction = direction
  end

  def assign_action_attributes(reaction)
    case action
    when :react
      reaction.emoji = emoji
      reaction.reaction_type = reaction_type
      reaction.status = :active
    when :unreact
      reaction.status = :removed
    else
      raise ArgumentError, "Unsupported reaction action: #{action}"
    end

    reaction.source_id = source_id if source_id.present?
    reaction.external_created_at = external_created_at if external_created_at.present?
    reaction.metadata = metadata if metadata.present?
  end
end
