module SortHandler
  extend ActiveSupport::Concern

  class_methods do
    def sort_on_last_activity_at(sort_direction = :desc)
      order(last_activity_at: sort_direction)
    end

    def sort_on_created_at(sort_direction = :asc)
      order(created_at: sort_direction)
    end

    def sort_on_priority(sort_direction = :desc)
      order(generate_sql_query("priority #{sort_direction.to_s.upcase} NULLS LAST, last_activity_at DESC"))
    end

    def sort_on_waiting_since(sort_direction = :asc)
      order(generate_sql_query("waiting_since #{sort_direction.to_s.upcase} NULLS LAST, created_at ASC"))
    end

    def sort_on_unread_count(sort_direction = :desc)
      # Count unread messages (messages created after agent_last_seen_at)
      # If agent_last_seen_at is NULL, consider all messages as unread
      select('conversations.*, COALESCE((
        SELECT COUNT(*)
        FROM messages
        WHERE messages.conversation_id = conversations.id
        AND messages.message_type = 0
        AND messages.private = false
        AND (conversations.agent_last_seen_at IS NULL OR messages.created_at > conversations.agent_last_seen_at)
      ), 0) as unread_count')
        .order(generate_sql_query("unread_count #{sort_direction.to_s.upcase}, last_activity_at DESC"))
    end

    def last_messaged_conversations
      Message.except(:order).select(
        'DISTINCT ON (conversation_id) conversation_id, id, created_at, message_type'
      ).order('conversation_id, created_at DESC')
    end

    def sort_on_last_user_message_at
      order('grouped_conversations.message_type', 'grouped_conversations.created_at ASC')
    end

    private

    def generate_sql_query(query)
      Arel::Nodes::SqlLiteral.new(sanitize_sql_for_order(query))
    end
  end
end
