# Request-local data for list serialization; never load entire message histories.
class Conversations::ListPreloader
  def initialize(conversations)
    @conversations = conversations.to_a
  end

  def perform
    return if @conversations.empty?

    preload_associations
    latest = latest_messages(Message.all)
    non_activity = latest_messages(Message.non_activity_messages)
    incoming = latest_messages(Message.incoming)
    preload_messages(latest.values + non_activity.values)
    counts = unread_counts

    @conversations.each do |conversation|
      conversation.list_preload_data = {
        latest_message: latest[conversation.id],
        last_non_activity_message: non_activity[conversation.id],
        last_incoming_message: incoming[conversation.id],
        unread_count: [counts.fetch(conversation.id, 0), 10].min
      }
    end
  end

  private

  def preload_associations
    ActiveRecord::Associations::Preloader.new(
      records: @conversations,
      associations: [:account, :team, :contact_inbox, { inbox: :channel },
                     { contact: { avatar_attachment: :blob } },
                     { assignee: [:account_users, { avatar_attachment: :blob }] },
                     { ai_assignee: { avatar_attachment: :blob } }]
    ).call
    Current.user.teams.load if Current.user.is_a?(User)
  end

  def latest_messages(scope)
    # DISTINCT ON returns at most one record per conversation, including on long threads.
    scope.joins(:conversation)
         .where(conversation_id: @conversations.map(&:id))
         .where('messages.account_id = conversations.account_id')
         .select('DISTINCT ON (messages.conversation_id) messages.*')
         .reorder('messages.conversation_id, messages.created_at DESC, messages.id DESC')
         .index_by(&:conversation_id)
  end

  def preload_messages(messages)
    conversations = @conversations.index_by(&:id)
    messages.each do |message|
      conversation = conversations.fetch(message.conversation_id)
      message.association(:conversation).target = conversation
      message.association(:inbox).target = conversation.inbox
    end
    ActiveRecord::Associations::Preloader.new(
      records: messages,
      associations: [{ attachments: { file_attachment: :blob } }, { sender: { avatar_attachment: :blob } }]
    ).call

    senders = messages.filter_map(&:sender).uniq
    ActiveRecord::Associations::Preloader.new(records: senders.grep(User), associations: :account_users).call
    ActiveRecord::Associations::Preloader.new(records: senders.grep(Contact), associations: :account).call
  end

  def unread_counts
    Message.incoming.joins(:conversation)
           .where(conversation_id: @conversations.map(&:id))
           .where('messages.account_id = conversations.account_id')
           .where('conversations.agent_last_seen_at IS NULL OR messages.created_at > conversations.agent_last_seen_at')
           .reorder(nil).group(:conversation_id).count
  end
end
