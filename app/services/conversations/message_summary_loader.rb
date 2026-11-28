# Loads the message summary of every given conversation in two queries, so that a page
# of conversations does not query its messages one conversation at a time.
class Conversations::MessageSummaryLoader
  # Answers the same questions as Conversations::MessageSummary, from values that are already loaded
  LoadedSummary = Data.define(:last_message, :last_non_activity_message, :unread_count)

  def initialize(conversations)
    @conversations = conversations
    @conversations_by_id = conversations.index_by(&:id)
  end

  # Returns the given conversations, so a controller can wrap the query that loads its page
  def perform
    return @conversations if @conversations_by_id.empty?

    rows = Conversations::MessageSummaryQuery.new(@conversations_by_id.keys).rows
    messages = load_messages(rows.flat_map { |row| [row.last_message_id, row.last_non_activity_message_id] })

    rows.each do |row|
      @conversations_by_id[row.conversation_id].message_summary = LoadedSummary.new(
        last_message: messages[row.last_message_id],
        last_non_activity_message: messages[row.last_non_activity_message_id],
        unread_count: row.unread_count
      )
    end
    @conversations
  end

  private

  def load_messages(message_ids)
    messages = Message.where(id: message_ids.compact.uniq).includes(message_preloads).index_by(&:id)
    # The message payload reads the unread count from its conversation, which has to be the one holding the loaded summary
    messages.each_value { |message| message.association(:conversation).target = @conversations_by_id[message.conversation_id] }
    messages
  end

  # What Message#push_event_data reads from each message
  def message_preloads
    [:inbox, { attachments: { file_attachment: :blob }, sender: [:account, :account_users, { avatar_attachment: :blob }] }]
  end
end
Conversations::MessageSummaryLoader.prepend_mod_with('Conversations::MessageSummaryLoader')
