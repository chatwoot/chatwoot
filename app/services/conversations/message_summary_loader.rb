# Sets message_summary on each of the given conversations, so that a page of conversations
# costs two queries instead of several per conversation.
class Conversations::MessageSummaryLoader
  def initialize(conversations)
    @conversations = conversations
    @conversations_by_id = conversations.index_by(&:id)
  end

  # Returns the given conversations, so a controller can wrap the query that loads its page
  def perform
    return @conversations if @conversations_by_id.empty?

    rows = Conversation.where(id: @conversations_by_id.keys).pluck(:id, last_message_id, last_non_activity_message_id, unread_count)
    messages = load_messages(rows.flat_map { |_, last_id, last_non_activity_id, _| [last_id, last_non_activity_id] }.compact.uniq)

    rows.each do |id, last_id, last_non_activity_id, unread_count|
      @conversations_by_id[id].message_summary = Conversations::MessageSummary.new(
        last_message: messages[last_id], last_non_activity_message: messages[last_non_activity_id], unread_count: unread_count
      )
    end
    @conversations
  end

  private

  def last_message_id
    latest_id(conversation_messages)
  end

  def last_non_activity_message_id
    latest_id(conversation_messages.non_activity_messages)
  end

  def unread_count
    unread_messages = Message.unscoped
                             .where(Conversation.unread_messages_condition(Message.arel_table, Conversation.arel_table))
                             .limit(Conversation::UNREAD_INCOMING_MESSAGES_LIMIT)
    Arel.sql("(SELECT COUNT(*) FROM (#{unread_messages.select('1').to_sql}) unread_messages)")
  end

  # Messages of the conversation row in the outer query
  def conversation_messages
    Message.unscoped.where('messages.conversation_id = conversations.id AND messages.account_id = conversations.account_id')
  end

  # The dashboard seeds the message thread from the latest message and then paginates BACKWARD
  # by id (before: messages[0].id). Keep the seed as the chronologically latest message,
  # but add an id tiebreaker: without it, same-second siblings (e.g. the input_csat survey
  # created alongside activity messages during an auto-resolve burst) could resolve to a
  # lower-id activity, and backward pagination would then never load the higher-id survey.
  def latest_id(messages)
    Arel.sql("(#{messages.reorder(created_at: :desc, id: :desc).limit(1).select(:id).to_sql})")
  end

  def load_messages(ids)
    return {} if ids.empty?

    messages = Message.where(id: ids).includes(
      attachments: { file_attachment: :blob }, sender: [:account_users, { avatar_attachment: :blob }]
    )
    messages.index_by(&:id).each_value do |message|
      message.association(:conversation).target = @conversations_by_id[message.conversation_id]
    end
  end
end
