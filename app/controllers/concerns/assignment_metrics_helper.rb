# frozen_string_literal: true

module AssignmentMetricsHelper
  extend ActiveSupport::Concern

  private

  def compute_summary_metrics
    conversations = filter_conversations_by_date_range

    {
      total_assignments: conversations.count,
      average_assignment_time: calculate_average_assignment_time(conversations),
      assignments_per_agent: calculate_assignments_per_agent(conversations),
      unassigned_conversations: Current.account.conversations.open.unassigned.count,
      policies_active: Current.account.assignment_policies.enabled.count
    }
  end

  def compute_inbox_metrics
    inboxes = params[:inbox_id].present? ? Current.account.inboxes.where(id: params[:inbox_id]) : Current.account.inboxes

    inboxes.map do |inbox|
      conversations = filter_conversations_by_date_range.where(inbox_id: inbox.id)
      {
        inbox_id: inbox.id,
        inbox_name: inbox.name,
        total_assignments: conversations.count,
        average_assignment_time: calculate_average_assignment_time(conversations),
        unique_agents: conversations.where.not(assignee_id: nil).distinct.count(:assignee_id),
        assignment_policy: inbox.assignment_policy&.name
      }
    end
  end

  def compute_agent_metrics
    agents = Current.account.users.joins(:account_users).where(account_users: { role: %w[agent administrator] })

    agents.map do |agent|
      conversations = filter_conversations_by_date_range.where(assignee_id: agent.id)
      {
        agent_id: agent.id,
        agent_name: agent.name,
        agent_email: agent.email,
        assignment_count: conversations.count,
        average_resolution_time: calculate_average_resolution_time(conversations),
        current_load: agent.assigned_conversations.open.count,
        capacity_utilization: compute_agent_capacity_utilization(agent)
      }
    end
  end

  def compute_policy_metrics
    Current.account.assignment_policies.enabled.map do |policy|
      compute_policy_performance(policy)
    end
  end

  def filter_conversations_by_date_range
    Current.account.conversations.where(created_at: date_range)
  end

  def date_range
    @date_range ||= params[:since]..params[:until]
  end

  def calculate_average_assignment_time(_conversations)
    # Implementation
    0
  end

  def calculate_assignments_per_agent(conversations)
    agents_count = conversations.where.not(assignee_id: nil).distinct.count(:assignee_id)
    return 0 if agents_count.zero?

    (conversations.count.to_f / agents_count).round(2)
  end

  def calculate_average_resolution_time(_conversations)
    # Implementation
    0
  end

  def compute_agent_capacity_utilization(_agent)
    # Implementation
    0.0
  end

  def calculate_assignment_success_rate(_conversations)
    # Implementation
    100.0
  end

  def serialize_agent(agent)
    {
      id: agent.id,
      name: agent.name,
      email: agent.email
    }
  end

  def group_by_hour(conversations)
    conversations.group_by_hour(:created_at).count
  end

  def group_by_day(conversations)
    conversations.group_by_day(:created_at).count
  end

  def group_by_week(conversations)
    conversations.group_by_week(:created_at).count
  end

  def group_by_month(conversations)
    conversations.group_by_month(:created_at).count
  end
end
