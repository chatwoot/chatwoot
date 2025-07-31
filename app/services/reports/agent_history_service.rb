# frozen_string_literal: true

class Reports::AgentHistoryService
  attr_reader :account, :params

  def initialize(account, params = {})
    @account = account
    @params = params
  end

  def fetch_agent_assignment_history(agent)
    conversations = agent.assigned_conversations
                         .includes(:inbox, :contact)
                         .where(created_at: date_range)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(params[:per_page] || 50)

    conversations.map do |conversation|
      {
        conversation_id: conversation.id,
        inbox_id: conversation.inbox_id,
        inbox_name: conversation.inbox.name,
        contact_name: conversation.contact.name,
        assigned_at: conversation.assignee_last_seen_at || conversation.created_at,
        status: conversation.status,
        created_at: conversation.created_at
      }
    end
  end

  def compute_all_agents_history
    agents = account.users.joins(:account_users).where(account_users: { role: %w[agent administrator] })

    agents.map do |agent|
      conversations = agent.assigned_conversations.where(created_at: date_range)
      {
        agent: serialize_agent(agent),
        total_assignments: conversations.count,
        resolved_count: conversations.resolved.count,
        open_count: conversations.open.count,
        average_resolution_time: calculate_average_resolution_time(conversations.resolved)
      }
    end
  end

  private

  def date_range
    start_date = params[:start_date] ? Date.parse(params[:start_date]).beginning_of_day : 30.days.ago
    end_date = params[:end_date] ? Date.parse(params[:end_date]).end_of_day : Time.current
    start_date..end_date
  end

  def serialize_agent(agent)
    {
      id: agent.id,
      name: agent.name,
      email: agent.email,
      avatar_url: agent.avatar_url
    }
  end

  def calculate_average_resolution_time(conversations)
    return 0 if conversations.empty?

    total_time = conversations.sum { |c| (c.last_activity_at - c.created_at) / 1.hour }
    (total_time / conversations.count).round(2)
  end
end
