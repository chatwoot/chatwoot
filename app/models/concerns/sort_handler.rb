module SortHandler
  extend ActiveSupport::Concern

  class_methods do
    # Every sort ends on the id so the order is total: offset pagination over rows that tie on the
    # sort keys would otherwise return one of them on two pages and skip another.
    def sort_on_last_activity_at(sort_direction = :desc)
      order(last_activity_at: sort_direction, id: sort_direction)
    end

    def sort_on_created_at(sort_direction = :asc)
      order(created_at: sort_direction, id: sort_direction)
    end

    # Columns are table-qualified because these sorts also run on relations that join contacts,
    # messages or conversation_pins, which carry columns by the same name.
    def sort_on_priority(sort_direction = :desc)
      order(generate_sql_query("priority #{sort_direction.to_s.upcase} NULLS LAST, #{table_name}.last_activity_at DESC, #{table_name}.id DESC"))
    end

    def sort_on_priority_created_at(sort_direction = :desc)
      order(generate_sql_query("priority #{sort_direction.to_s.upcase} NULLS LAST, #{table_name}.created_at ASC, #{table_name}.id ASC"))
    end

    def sort_on_waiting_since(sort_direction = :asc)
      order(generate_sql_query(
              "(waiting_since IS NULL), waiting_since #{sort_direction.to_s.upcase}, #{table_name}.created_at ASC, #{table_name}.id ASC"
            ))
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
