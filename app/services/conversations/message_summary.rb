# What a conversation payload shows from the conversation's messages.
class Conversations::MessageSummary
  def initialize(conversation)
    @conversation = conversation
  end

  # The dashboard seeds the message thread from this message and then paginates BACKWARD
  # by id (before: messages[0].id). Keep the seed as the chronologically latest message,
  # but add an id tiebreaker: without it, same-second siblings (e.g. the input_csat survey
  # created alongside activity messages during an auto-resolve burst) could resolve to a
  # lower-id activity, and backward pagination would then never load the higher-id survey.
  def last_message
    messages.includes([{ attachments: [{ file_attachment: [:blob] }] }]).reorder(created_at: :desc, id: :desc).first
  end

  def last_non_activity_message
    messages.non_activity_messages.first
  end

  def unread_count
    @conversation.unread_incoming_messages.count
  end

  private

  def messages
    @conversation.messages.where(account_id: @conversation.account_id)
  end
end
