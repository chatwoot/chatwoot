class Conversations::ReadStateService
  FEATURE_FLAG = 'individual_conversation_reads'.freeze

  pattr_initialize [:conversation!, :user!]

  def self.enabled?(account, user)
    user.is_a?(User) && account.feature_enabled?(FEATURE_FLAG)
  end

  def last_seen_at
    record&.last_seen_at || conversation.read_baseline_at
  end

  def incoming_messages
    messages = conversation.messages.where(account_id: conversation.account_id).incoming
    last_seen_at ? messages.where(Message.arel_table[:created_at].gt(last_seen_at)) : messages
  end

  def payload
    { agent_last_seen_at: last_seen_at.to_i, unread_count: incoming_messages.limit(10).count }
  end

  def mark_read
    now = Time.current
    return if last_seen_at && last_seen_at >= 1.hour.ago && !conversation.messages.created_since(last_seen_at).exists?

    write(now, monotonic: true)
    update_shared_read_metadata(now)
    notify_user
  end

  def mark_unread
    last_message = conversation.messages.incoming.order(created_at: :desc, id: :desc).first
    write(last_message ? last_message.created_at - 1.second : Time.at(0).utc, monotonic: false)
    notify_user
  end

  private

  def update_shared_read_metadata(now)
    updates = { agent_last_seen_at: [conversation.agent_last_seen_at, now].compact.max }
    updates[:assignee_last_seen_at] = now if conversation.assignee_id == user.id
    conversation.update_columns(updates) # rubocop:disable Rails/SkipsModelValidations
    Conversations::UnreadCounts::Refresher.new(conversation).perform
  end

  def record
    return @record if defined?(@record)

    @record = if conversation.conversation_read_states.loaded?
                conversation.conversation_read_states.detect { |state| state.user_id == user.id }
              else
                conversation.conversation_read_states.find_by(user_id: user.id)
              end
  end

  def write(timestamp, monotonic:)
    options = { unique_by: [:user_id, :conversation_id] }
    if monotonic
      options[:on_duplicate] =
        Arel.sql('last_seen_at = GREATEST(conversation_read_states.last_seen_at, EXCLUDED.last_seen_at), updated_at = EXCLUDED.updated_at')
    end
    # The unique index makes simultaneous opens from different tabs one atomic receipt.
    # rubocop:disable Rails/SkipsModelValidations
    ConversationReadState.upsert(
      { account_id: conversation.account_id, conversation_id: conversation.id, user_id: user.id, last_seen_at: timestamp },
      **options
    )
    # rubocop:enable Rails/SkipsModelValidations
    remove_instance_variable(:@record) if defined?(@record)
    conversation.conversation_read_states.reset
  end

  def notify_user
    account = conversation.account
    Conversations::UnreadCounts::FilteredCountInvalidator.new(account).user_visibility_changed!(user_id: user.id)
    data = payload.merge(id: conversation.display_id, inbox_id: conversation.inbox_id, account_id: account.id)
    ActionCableBroadcastJob.perform_later([user.pubsub_token], 'conversation.read_state_changed', data)
    ActionCableBroadcastJob.perform_later([user.pubsub_token], 'conversation.unread_count_changed', { account_id: account.id })
  end
end
