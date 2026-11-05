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

    rows = Conversation.message_summary_rows(@conversations_by_id.keys).index_by(&:first)
    messages = load_messages(rows.values.flat_map { |_, last_id, last_non_activity_id, _| [last_id, last_non_activity_id] }.compact.uniq)

    @conversations_by_id.each do |id, conversation|
      # A conversation deleted after its page loaded has no row, so it renders without messages
      _, last_id, last_non_activity_id, unread_count = rows[id]
      conversation.message_summary = Conversations::MessageSummary.new(
        last_message: messages[last_id], last_non_activity_message: messages[last_non_activity_id], unread_count: unread_count || 0
      )
    end
    @conversations
  end

  private

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
