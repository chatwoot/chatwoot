# frozen_string_literal: true

module DistributionMetrics
  extend ActiveSupport::Concern

  def compute_distribution_by_day_of_week
    filter_conversations_by_date_range
      .group_by_day_of_week(:created_at)
      .count
  end

  def compute_policy_performance(policy)
    inbox_ids = policy.inboxes.pluck(:id)
    conversations = filter_conversations_by_date_range.where(inbox_id: inbox_ids)

    {
      policy_id: policy.id,
      policy_name: policy.name,
      assignment_order: policy.assignment_order,
      total_assignments: conversations.count,
      average_assignment_time: calculate_average_assignment_time(conversations),
      success_rate: calculate_assignment_success_rate(conversations),
      inbox_count: inbox_ids.count
    }
  end

  def compute_agent_utilization(agent)
    capacity_policy = agent.account_users.first&.agent_capacity_policy
    assigned_conversations = agent.assigned_conversations.open.count

    utilization = if capacity_policy
                    policy_limit = capacity_policy.inbox_capacity_limits.sum(:conversation_limit)
                    policy_limit.positive? ? (assigned_conversations.to_f / policy_limit * 100).round(2) : 0
                  else
                    0
                  end

    {
      agent: serialize_agent(agent),
      assigned_conversations: assigned_conversations,
      capacity_policy: capacity_policy&.name,
      utilization_percentage: utilization,
      available_capacity: capacity_policy ? capacity_policy.inbox_capacity_limits.sum(:conversation_limit) - assigned_conversations : nil
    }
  end

  def compute_distribution_by_inbox
    filter_conversations_by_date_range
      .joins(:inbox)
      .group('inboxes.id', 'inboxes.name')
      .count
      .map { |k, v| { inbox_id: k[0], inbox_name: k[1], count: v } }
  end

  def compute_distribution_by_team
    filter_conversations_by_date_range
      .joins(assignee: { team_members: :team })
      .group('teams.id', 'teams.name')
      .count
      .map { |k, v| { team_id: k[0], team_name: k[1], count: v } }
  end

  def compute_distribution_by_hour
    filter_conversations_by_date_range
      .group_by_hour_of_day(:created_at)
      .count
  end

  def calculate_average_resolution_time(conversations)
    resolved = conversations.resolved
    return 0 if resolved.empty?

    total_time = resolved.sum { |c| (c.last_activity_at - c.created_at) / 1.hour }
    (total_time / resolved.count).round(2)
  end

  def calculate_assignment_success_rate(conversations)
    total = conversations.count
    return 0.0 if total.zero?

    successful = conversations.where(status: %w[resolved snoozed]).count
    (successful.to_f / total * 100).round(2)
  end

  def pagination_meta
    {
      current_page: params[:page] || 1,
      per_page: params[:per_page] || 50,
      total_count: @assignment_history&.total_count || 0
    }
  end
end
