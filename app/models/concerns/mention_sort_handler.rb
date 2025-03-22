module MentionSortHandler
  extend ActiveSupport::Concern

  included do
    # Sort by conversation's creation date (newest first)
    scope :sort_on_created_at, lambda {
      joins(:conversation).order('conversations.created_at DESC')
    }

    # Sort by last user message timestamp
    scope :last_user_message_at, lambda {
      joins(:conversation)
        .joins('LEFT JOIN messages ON messages.conversation_id = conversations.id')
        .where(messages: { message_type: :incoming })
        .group('mentions.id')
        .order('MAX(messages.created_at) DESC NULLS LAST')
    }

    # Sort by mention's creation date (default sorting - newest first)
    scope :latest, lambda {
      order(created_at: :desc)
    }
  end

  class_methods do
    def sort_on_last_activity_at(sort_direction = :desc)
      joins(:conversation).order(generate_sql_query("conversations.last_activity_at #{sort_direction.to_s.upcase} NULLS LAST"))
    end

    def sort_on_created_at(sort_direction = :desc)
      joins(:conversation).order(generate_sql_query("conversations.created_at #{sort_direction.to_s.upcase} NULLS LAST"))
    end

    def sort_on_priority(sort_direction = :desc)
      joins(:conversation).order(
        generate_sql_query(
          "conversations.priority #{sort_direction.to_s.upcase} NULLS LAST, " \
          'conversations.last_activity_at DESC'
        )
      )
    end

    def sort_on_waiting_since(sort_direction = :asc)
      joins(:conversation).order(
        generate_sql_query(
          "conversations.waiting_since #{sort_direction.to_s.upcase} NULLS LAST, " \
          'conversations.created_at ASC'
        )
      )
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
