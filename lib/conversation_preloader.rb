# Improves performance by preloading conversation data in batches to reduce database queries
module ConversationPreloader
  # Skip preloading if searching or no conversations exist
  def preload_data_if_needed(result_conversations, params)
    return if params[:q].present? || result_conversations.empty?

    preload_conversation_data(result_conversations)
  end

  # Orchestrates preloading for all conversations in batches
  def preload_conversation_data(conversations)
    return if conversations.empty?

    conversation_ids = conversations.map(&:id)
    account_id = conversations.first.account_id

    # Process in batches to improve memory usage
    batch_size = 50
    conversation_ids.each_slice(batch_size) do |batch_ids|
      process_conversation_batch(conversations, batch_ids, account_id)
    end
  end

  # Fetches and attaches data for a batch of conversations
  def process_conversation_batch(conversations, batch_ids, account_id)
    message_data = fetch_message_data(batch_ids, account_id)
    unread_counts = calculate_unread_counts_for_batch(conversations, batch_ids)
    batch_ids.each do |conversation_id|
      attach_preloaded_data(
        conversations,
        conversation_id,
        message_data[:last_messages],
        message_data[:last_non_activity_messages],
        unread_counts[conversation_id] || 0
      )
    end
  rescue StandardError => e
    # Log errors but continue processing
    Rails.logger.error("PRELOADER: Error in conversation preloading for batch: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end

  # Fetches all message data in consolidated queries
  def fetch_message_data(batch_ids, account_id)
    # Get latest messages of any type
    latest_message_data = fetch_latest_messages(batch_ids, account_id)

    # Get latest user/agent messages (excluding system messages)
    latest_non_activity_data = fetch_latest_non_activity_messages(batch_ids, account_id)

    {
      last_messages: latest_message_data[:messages],
      last_non_activity_messages: latest_non_activity_data[:messages]
    }
  end

  # Gets latest messages for all conversations in one query
  def fetch_latest_messages(batch_ids, account_id)
    # Use VALUES clause for better performance with large sets of conversation IDs
    query = <<-SQL.squish
      SELECT c.conversation_id, m.*
      FROM (
        VALUES #{batch_ids.map { |id| "(#{id})" }.join(',')}
      ) AS c(conversation_id)
      CROSS JOIN LATERAL (
        SELECT m.*
        FROM messages m
        WHERE m.conversation_id = c.conversation_id
        AND m.account_id = ?
        ORDER BY m.created_at DESC
        LIMIT 1
      ) m
    SQL

    # Execute raw SQL to avoid ActiveRecord adding additional ordering
    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [query, account_id])
    )

    # Convert result to Message objects
    messages = result.map do |row|
      Message.instantiate(row)
    end

    # Build the hash structures matching the original method
    ids_by_conversation = {}
    message_hash = {}

    messages.each do |message|
      ids_by_conversation[message.conversation_id] = message.id
      message_hash[message.conversation_id] = message
    end

    # Load attachments in a single query to reduce database round trips
    if ids_by_conversation.present?
      Message.where(id: ids_by_conversation.values)
             .includes(attachments: [{ file_attachment: [:blob] }])
             .each do |message_with_attachments|
        message_hash[message_with_attachments.conversation_id] = message_with_attachments
      end
    end

    { ids_by_conversation: ids_by_conversation, messages: message_hash }
  end

  # Gets latest non-system messages in one query
  def fetch_latest_non_activity_messages(batch_ids, account_id)
    # Use VALUES clause for better performance with large sets of conversation IDs
    query = <<-SQL.squish
      SELECT c.conversation_id, m.*
      FROM (
        VALUES #{batch_ids.map { |id| "(#{id})" }.join(',')}
      ) AS c(conversation_id)
      CROSS JOIN LATERAL (
        SELECT m.*
        FROM messages m
        WHERE m.conversation_id = c.conversation_id
        AND m.account_id = ?
        AND m.message_type != ?
        ORDER BY m.created_at DESC
        LIMIT 1
      ) m
    SQL

    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [query, account_id, Message.message_types[:activity]])
    )

    messages = result.map do |row|
      Message.instantiate(row)
    end

    ids_by_conversation = {}
    message_hash = {}

    messages.each do |message|
      ids_by_conversation[message.conversation_id] = message.id
      message_hash[message.conversation_id] = message
    end

    { ids_by_conversation: ids_by_conversation, messages: message_hash }
  end

  # Attaches preloaded data to a conversation object
  def attach_preloaded_data(conversations, conversation_id, last_messages, last_non_activity_messages, unread_count = 0)
    conversation = conversations.find { |c| c.id == conversation_id }
    return unless conversation

    # Debug: Log the last message for the conversation
    last_message = last_messages[conversation_id]

    # Store data as instance variables
    conversation.instance_variable_set(:@preloaded_last_message, last_message)
    conversation.instance_variable_set(
      :@preloaded_last_non_activity_message,
      last_non_activity_messages[conversation_id]
    )
    conversation.instance_variable_set(:@preloaded_unread_count, unread_count)

    # Add methods to access preloaded data
    define_accessor_methods(conversation)
  rescue StandardError => e
    Rails.logger.error("PRELOADER: Error attaching preloaded data to conversation #{conversation_id}: #{e.message}")
  end

  # Calculates unread message count, capped at 10
  def calculate_unread_count(conversation, conversation_id)
    last_seen_time = conversation.agent_last_seen_at || 30.days.ago
    cutoff_time = [last_seen_time, 30.days.ago].max

    # Limit query to 11 records for efficiency
    count = Message.where(
      conversation_id: conversation_id,
      message_type: Message.message_types[:incoming]
    ).where('created_at > ?', cutoff_time).limit(11).count

    [count, 10].min
  end

  # Calculates unread counts for a batch of conversations in a single query
  def calculate_unread_counts_for_batch(conversations, _conversation_ids)
    # Get all seen times in one go
    counts = {}
    conversations.each do |conversation|
      counts[conversation.id] = calculate_unread_count(conversation, conversation.id)
    end
    counts
  end

  # Adds accessor methods to retrieve preloaded data
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
