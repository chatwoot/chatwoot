module ConversationPreloader
  def preload_data_if_needed(result_conversations, params)
    return if params[:q].present? || result_conversations.empty?

    preload_conversation_data(result_conversations)
  end

  def preload_conversation_data(conversations)
    return if conversations.empty?

    conversation_ids = conversations.pluck('conversations.id')
    account_id = conversations.first.account_id

    batch_size = 50
    conversation_ids.each_slice(batch_size) do |batch_ids|
      process_conversation_batch(conversations, batch_ids, account_id)
    end
  end

  def process_conversation_batch(conversations, batch_ids, account_id)
    message_data = fetch_message_data(batch_ids, account_id)

    batch_ids.each do |conversation_id|
      attach_preloaded_data(
        conversations,
        conversation_id,
        message_data[:last_messages],
        message_data[:last_non_activity_messages]
      )
    end
  rescue StandardError => e
    Rails.logger.error("Error in conversation preloading for batch: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end

  def fetch_message_data(batch_ids, account_id)
    # Get latest message IDs and data
    latest_message_data = fetch_latest_messages(batch_ids, account_id)

    # Get latest non-activity message IDs and data
    latest_non_activity_data = fetch_latest_non_activity_messages(batch_ids, account_id)

    {
      last_messages: latest_message_data[:messages],
      last_non_activity_messages: latest_non_activity_data[:messages]
    }
  end

  def fetch_latest_messages(batch_ids, account_id)
    message_id_rows = Message.where(conversation_id: batch_ids, account_id: account_id)
                             .group(:conversation_id)
                             .select('conversation_id, MAX(id) AS max_id')

    ids_by_conversation = {}
    message_id_rows.each do |row|
      ids_by_conversation[row.conversation_id] = row.max_id
    end

    message_ids = ids_by_conversation.values
    messages = Message.where(id: message_ids)
                      .includes(attachments: [{ file_attachment: [:blob] }])
                      .index_by(&:conversation_id)

    { ids_by_conversation: ids_by_conversation, messages: messages }
  end

  def fetch_latest_non_activity_messages(batch_ids, account_id)
    id_rows = Message.where(conversation_id: batch_ids, account_id: account_id)
                     .where.not(message_type: Message.message_types[:activity])
                     .group(:conversation_id)
                     .select('conversation_id, MAX(id) AS max_id')

    ids_by_conversation = {}
    id_rows.each do |row|
      ids_by_conversation[row.conversation_id] = row.max_id
    end

    message_ids = ids_by_conversation.values
    messages = Message.where(id: message_ids).index_by(&:conversation_id)

    { ids_by_conversation: ids_by_conversation, messages: messages }
  end

  def attach_preloaded_data(conversations, conversation_id, last_messages, last_non_activity_messages)
    conversation = conversations.find { |c| c.id == conversation_id }
    return unless conversation

    unread_count = calculate_unread_count(conversation, conversation_id)

    # Set instance variables on the conversation object
    conversation.instance_variable_set(:@preloaded_last_message, last_messages[conversation_id])
    conversation.instance_variable_set(
      :@preloaded_last_non_activity_message,
      last_non_activity_messages[conversation_id]
    )
    conversation.instance_variable_set(:@preloaded_unread_count, unread_count)

    # Add accessor methods to the conversation instance
    define_accessor_methods(conversation)
  rescue StandardError => e
    Rails.logger.error("Error attaching preloaded data to conversation #{conversation_id}: #{e.message}")
  end

  def calculate_unread_count(conversation, conversation_id)
    last_seen_time = conversation.agent_last_seen_at || 30.days.ago
    cutoff_time = [last_seen_time, 30.days.ago].max

    # Limit count to 10 for performance
    count = Message.where(
      conversation_id: conversation_id,
      message_type: Message.message_types[:incoming]
    ).where('created_at > ?', cutoff_time).limit(11).count

    [count, 10].min
  end

  def define_accessor_methods(conversation)
    conversation.singleton_class.class_eval do
      define_method(:preloaded_last_message) do
        instance_variable_get(:@preloaded_last_message)
      end

      define_method(:preloaded_last_non_activity_message) do
        instance_variable_get(:@preloaded_last_non_activity_message)
      end

      define_method(:preloaded_unread_count) do
        instance_variable_get(:@preloaded_unread_count)
      end
    end
  end
end
