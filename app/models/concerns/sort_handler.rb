module SortHandler
  extend ActiveSupport::Concern

  included do
    def self.latest(sort_order = :desc)
      order(last_activity_at: sort_order)
    end

    def self.sort_on_created_at(sort_order = :asc)
      order(created_at: sort_order)
    end

    def self.last_messaged_conversations(sort_order = :desc)
      Message.except(:order).select(
        'DISTINCT ON (conversation_id) conversation_id, id, created_at, message_type'
      ).order("conversation_id, created_at #{sort_order.to_s.upcase}")
    end

    def self.sort_on_last_user_message_at(sort_order = :asc)
      order(
        "grouped_conversations.message_type #{sort_order.to_s.upcase}",
        "grouped_conversations.created_at #{sort_order.to_s.upcase}"
      )
    end

    def self.sort_on_priority(sort_order = :desc)
      order(
        Arel::Nodes::SqlLiteral.new(
          sanitize_sql_for_order(
            "CASE WHEN priority IS NULL THEN 0 ELSE priority END #{sort_order.to_s.upcase}, last_activity_at #{sort_order.to_s.upcase}"
          )
        )
      )
    end

    def self.sort_on_waiting_since(sort_order = :asc)
      order(
        Arel::Nodes::SqlLiteral.new(
          sanitize_sql_for_order(
            "CASE WHEN waiting_since IS NULL THEN now() ELSE waiting_since END #{sort_order.to_s.upcase}, created_at #{sort_order.to_s.upcase}"
          )
        )
      )
    end
  end
end
