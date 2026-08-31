# Conversation activity + event dispatch side-effects for a persisted MessageReaction.
#
# Given the state of the reaction before and after Messages::Reactions::UpsertService assigned
# and saved it, decides whether this call is a real create/update/removal (bump conversation
# activity + dispatch an event) or a no-op duplicate (do nothing).
class Messages::Reactions::ActivityService
  include Events::Types

  def initialize(reaction:, was_new_record:, previous_status:, previous_emoji:, previous_reaction_type:)
    @reaction = reaction
    @was_new_record = was_new_record
    @previous_status = previous_status
    @previous_emoji = previous_emoji
    @previous_reaction_type = previous_reaction_type
  end

  def perform
    event = event_name
    return if event.blank?

    bump_conversation_activity
    dispatch(event)
  end

  private

  attr_reader :reaction, :was_new_record, :previous_status, :previous_emoji, :previous_reaction_type

  delegate :message, :conversation, :account, :inbox, :sender, to: :reaction

  def event_name
    if was_new_record
      # A row that never existed before is always CREATED, unless the very first thing we ever
      # recorded for it is an :unreact (nothing active was ever visible) -- treat that as REMOVED.
      reaction.active? ? MESSAGE_REACTION_CREATED : MESSAGE_REACTION_REMOVED
    elsif reaction.removed?
      MESSAGE_REACTION_REMOVED if previous_status == 'active'
    elsif reaction_changed?
      MESSAGE_REACTION_UPDATED
    end
  end

  def reaction_changed?
    previous_emoji != reaction.emoji ||
      previous_reaction_type != reaction.reaction_type ||
      previous_status != reaction.status
  end

  def bump_conversation_activity
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(last_activity_at: reaction.external_created_at || Time.current, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def dispatch(event)
    Rails.configuration.dispatcher.dispatch(
      event,
      Time.zone.now,
      message_reaction: reaction,
      message: message,
      conversation: conversation,
      account: account,
      inbox: inbox,
      sender: sender
    )
  end
end
