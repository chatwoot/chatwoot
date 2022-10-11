module SortHandler
  extend ActiveSupport::Concern

  included do
    def self.latest
      order(last_activity_at: :desc)
    end

    def self.sort_on_created_at
      order(created_at: :asc)
    end

    def self.last_messaged_conversations
      Message.except(:order).select(
        'DISTINCT ON (conversation_id) conversation_id, id, created_at, message_type'
      ).order('conversation_id, created_at DESC')
    end

    def self.sort_on_last_user_message_at
      order(
        'grouped_conversations.message_type', 'grouped_conversations.created_at ASC'
      )
    end
  end
end
