# Loads what the conversation payload needs from messages for a whole page of conversations at once:
# the latest message, the latest non-activity message and the unread count.
class Conversations::MessageSummaryLoader
  UNREAD_COUNT_LIMIT = 10

  CONVERSATION_MESSAGES = <<~SQL.squish.freeze
    FROM messages
    WHERE messages.conversation_id = conversations.id AND messages.account_id = conversations.account_id
  SQL

  # The dashboard seeds the message thread from this message and then paginates BACKWARD
  # by id (before: messages[0].id). Keep the seed as the chronologically latest message,
  # but add an id tiebreaker: without it, same-second siblings (e.g. the input_csat survey
  # created alongside activity messages during an auto-resolve burst) could resolve to a
  # lower-id activity, and backward pagination would then never load the higher-id survey.
  LATEST_MESSAGE_ORDER = 'ORDER BY messages.created_at DESC, messages.id DESC LIMIT 1'.freeze

  LAST_MESSAGE_ID = "(SELECT messages.id #{CONVERSATION_MESSAGES} #{LATEST_MESSAGE_ORDER})".freeze

  LAST_NON_ACTIVITY_MESSAGE_ID = <<~SQL.squish.freeze
    (SELECT messages.id #{CONVERSATION_MESSAGES}
      AND messages.message_type != #{Message.message_types[:activity]}
      #{LATEST_MESSAGE_ORDER})
  SQL

  UNREAD_COUNT = <<~SQL.squish.freeze
    (SELECT COUNT(*) FROM (
      SELECT 1 #{CONVERSATION_MESSAGES}
        AND messages.message_type = #{Message.message_types[:incoming]}
        AND (conversations.agent_last_seen_at IS NULL OR messages.created_at > conversations.agent_last_seen_at)
      LIMIT #{UNREAD_COUNT_LIMIT}
    ) unread_messages)
  SQL

  def initialize(conversations)
    @conversations = conversations.index_by(&:id)
    @summaries = load_summaries
    @message_data = load_message_data
  end

  def last_message_data(conversation)
    @message_data[@summaries[conversation.id].first]
  end

  def last_non_activity_message_data(conversation)
    @message_data[@summaries[conversation.id].second]
  end

  def unread_count(conversation)
    @summaries[conversation.id].third
  end

  private

  def load_summaries
    return {} if @conversations.empty?

    Conversation.where(id: @conversations.keys)
                .pluck(:id, Arel.sql(LAST_MESSAGE_ID), Arel.sql(LAST_NON_ACTIVITY_MESSAGE_ID), Arel.sql(UNREAD_COUNT))
                .to_h { |id, *summary| [id, summary] }
  end

  def load_message_data
    message_ids = @summaries.values.flat_map { |last_id, last_non_activity_id, _| [last_id, last_non_activity_id] }.compact.uniq
    return {} if message_ids.empty?

    messages = Message.where(id: message_ids).includes(
      attachments: { file_attachment: :blob }, sender: [:account_users, { avatar_attachment: :blob }]
    )
    messages.to_h do |message|
      conversation = @conversations[message.conversation_id]
      message.association(:conversation).target = conversation
      [message.id, message.push_event_data(unread_count: unread_count(conversation))]
    end
  end
end
