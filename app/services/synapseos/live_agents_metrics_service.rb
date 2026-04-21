module Synapseos
  class LiveAgentsMetricsService
    def initialize(account)
      @account = account
    end

    def call
      @account.account_users.includes(user: { avatar_attachment: :blob }).map do |account_user|
        agent_payload(account_user)
      end
    end

    private

    def agent_payload(account_user)
      user = account_user.user
      {
        id: user.id,
        name: user.name,
        email: user.email,
        thumbnail: user.avatar_url,
        availability: account_user.availability_status,
        role: account_user.role,
        open_conversations: open_conversations_count(user.id),
        conversations_today: conversations_today_count(user.id),
        avg_first_response_seconds: avg_first_response_today(user.id),
        last_activity_at: user.last_sign_in_at
      }
    end

    def open_conversations_count(user_id)
      @account.conversations.open.where(assignee_id: user_id).count
    end

    def conversations_today_count(user_id)
      @account.conversations
              .where(assignee_id: user_id)
              .where('updated_at >= ?', Time.current.beginning_of_day)
              .count
    end

    def avg_first_response_today(user_id)
      avg = ReportingEvent
            .where(account_id: @account.id, user_id: user_id, name: 'first_response')
            .where('created_at >= ?', Time.current.beginning_of_day)
            .average(:value)
      avg&.to_f&.round
    end
  end
end
