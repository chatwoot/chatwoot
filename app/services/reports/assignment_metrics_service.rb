# frozen_string_literal: true

class Reports::AssignmentMetricsService
  attr_reader :account, :params

  def initialize(account, params = {})
    @account = account
    @params = params
  end

  def compute_assignment_metrics
    {
      total_assigned: total_assigned_conversations,
      assignment_rate: calculate_assignment_rate,
      average_response_time: calculate_average_response_time,
      average_resolution_time: calculate_average_resolution_time,
      assignments_by_policy: assignments_by_policy,
      period_metrics: compute_period_metrics
    }
  end

  def compute_policy_performance(policy)
    conversations = policy.assignment_logs
                          .joins(:conversation)
                          .where(conversations: { created_at: date_range })

    {
      policy_id: policy.id,
      policy_name: policy.name,
      total_assignments: conversations.count,
      average_assignment_time: calculate_average_time(conversations, :assignment_time),
      successful_assignments: conversations.where(success: true).count,
      failed_assignments: conversations.where(success: false).count
    }
  end

  def compute_agent_utilization(agent)
    conversations = agent.assigned_conversations.where(created_at: date_range)
    capacity_limit = fetch_agent_capacity_limit(agent)

    {
      agent_id: agent.id,
      agent_name: agent.name,
      current_load: agent.assigned_conversations.open.count,
      capacity_limit: capacity_limit,
      utilization_percentage: calculate_utilization_percentage(agent, capacity_limit),
      total_handled: conversations.count,
      average_handling_time: calculate_average_handling_time(conversations)
    }
  end

  def compute_distribution_by_inbox
    Conversation.joins(:inbox)
                .where(created_at: date_range, account_id: account.id)
                .where.not(assignee_id: nil)
                .group('inboxes.name')
                .count
  end

  def compute_distribution_by_team
    Conversation.joins(assignee: { team_members: :team })
                .where(created_at: date_range, account_id: account.id)
                .group('teams.name')
                .count
  end

  def compute_distribution_by_hour
    Conversation.where(created_at: date_range, account_id: account.id)
                .where.not(assignee_id: nil)
                .group_by_hour(:created_at, format: '%H')
                .count
  end

  def compute_period_metrics
    group_by = params[:group_by] || 'day'
    conversations = filter_conversations_by_date_range

    case group_by
    when 'hour'
      group_by_hour(conversations)
    when 'week'
      group_by_week(conversations)
    when 'month'
      group_by_month(conversations)
    else
      group_by_day(conversations)
    end
  end

  private

  def date_range
    @date_range ||= params[:since]..params[:until]
  end

  def filter_conversations_by_date_range
    Conversation.where(account_id: account.id, created_at: date_range)
  end

  def total_assigned_conversations
    filter_conversations_by_date_range.where.not(assignee_id: nil).count
  end

  def calculate_assignment_rate
    total = filter_conversations_by_date_range.count
    return 0.0 if total.zero?

    (total_assigned_conversations.to_f / total * 100).round(2)
  end

  def calculate_average_response_time
    # Implementation for average response time
    0
  end

  def calculate_average_resolution_time
    # Implementation for average resolution time
    0
  end

  def assignments_by_policy
    # Implementation for assignments by policy
    {}
  end

  def fetch_agent_capacity_limit(_agent)
    # Implementation to fetch agent capacity limit
    nil
  end

  def calculate_utilization_percentage(agent, capacity_limit)
    return 0.0 unless capacity_limit&.positive?

    current_load = agent.assigned_conversations.open.count
    (current_load.to_f / capacity_limit * 100).round(2)
  end

  def calculate_average_handling_time(_conversations)
    # Implementation for average handling time
    0
  end

  def calculate_average_time(_conversations, _field)
    # Implementation for average time calculation
    0
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
