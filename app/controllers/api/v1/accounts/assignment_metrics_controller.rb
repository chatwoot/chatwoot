# frozen_string_literal: true

class Api::V1::Accounts::AssignmentMetricsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :validate_date_range

  def index
    @metrics = compute_assignment_metrics
    render json: { assignment_metrics: @metrics }
  end

  def agent_history
    @agent = Current.account.users.find(params[:agent_id])
    @assignment_history = fetch_agent_assignment_history(@agent)
    
    render json: { 
      agent: serialize_agent(@agent),
      assignment_history: @assignment_history,
      meta: pagination_meta
    }
  end

  private

  def compute_assignment_metrics
    metrics = {
      summary: compute_summary_metrics,
      by_period: compute_period_metrics,
      by_inbox: compute_inbox_metrics,
      by_agent: compute_agent_metrics,
      by_policy: compute_policy_metrics
    }
    
    metrics
  end

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

  def compute_period_metrics
    group_by = params[:group_by] || 'day'
    conversations = filter_conversations_by_date_range

    case group_by
    when 'hour'
      group_by_hour(conversations)
    when 'day'
      group_by_day(conversations)
    when 'week'
      group_by_week(conversations)
    when 'month'
      group_by_month(conversations)
    else
      group_by_day(conversations)
    end
  end

  def compute_inbox_metrics
    inbox_id = params[:inbox_id]
    base_query = filter_conversations_by_date_range

    if inbox_id.present?
      base_query = base_query.where(inbox_id: inbox_id)
    end

    base_query.joins(:inbox)
              .group('inboxes.id', 'inboxes.name')
              .count
              .map { |k, v| { inbox_id: k[0], inbox_name: k[1], assignment_count: v } }
  end

  def compute_agent_metrics
    agent_id = params[:agent_id]
    base_query = filter_conversations_by_date_range.where.not(assignee_id: nil)

    if agent_id.present?
      base_query = base_query.where(assignee_id: agent_id)
    end

    base_query.joins(:assignee)
              .group('users.id', 'users.name', 'users.email')
              .count
              .map { |k, v| { agent_id: k[0], agent_name: k[1], agent_email: k[2], assignment_count: v } }
              .sort_by { |a| -a[:assignment_count] }
  end

  def compute_policy_metrics
    # Get metrics grouped by assignment policy
    policy_metrics = {}
    
    Current.account.assignment_policies.includes(:inboxes).each do |policy|
      inbox_ids = policy.inboxes.pluck(:id)
      next if inbox_ids.empty?
      
      conversations = filter_conversations_by_date_range.where(inbox_id: inbox_ids)
      
      policy_metrics[policy.id] = {
        policy_id: policy.id,
        policy_name: policy.name,
        assignment_order: policy.assignment_order,
        total_assignments: conversations.count,
        average_assignment_time: calculate_average_assignment_time(conversations),
        inbox_count: inbox_ids.count
      }
    end
    
    policy_metrics.values
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

  def filter_conversations_by_date_range
    Current.account.conversations.where(created_at: date_range)
  end

  def date_range
    start_date = params[:start_date] ? Date.parse(params[:start_date]).beginning_of_day : 30.days.ago
    end_date = params[:end_date] ? Date.parse(params[:end_date]).end_of_day : Time.current
    
    start_date..end_date
  end

  def validate_date_range
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      
      if start_date > end_date
        render json: { error: 'Start date must be before end date' }, status: :bad_request
      elsif (end_date - start_date).to_i > 365
        render json: { error: 'Date range cannot exceed 365 days' }, status: :bad_request
      end
    end
  rescue Date::Error
    render json: { error: 'Invalid date format' }, status: :bad_request
  end

  def calculate_average_assignment_time(conversations)
    assigned_conversations = conversations.where.not(assignee_id: nil)
    return 0 if assigned_conversations.empty?

    total_time = assigned_conversations.sum do |conv|
      assignment_time = conv.assignee_last_seen_at || conv.updated_at
      (assignment_time - conv.created_at).to_i
    end

    (total_time / assigned_conversations.count / 60).round(2) # Return in minutes
  end

  def calculate_assignments_per_agent(conversations)
    assigned_count = conversations.where.not(assignee_id: nil).count
    agent_count = conversations.where.not(assignee_id: nil).distinct.count(:assignee_id)
    
    return 0 if agent_count.zero?
    
    (assigned_count.to_f / agent_count).round(2)
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

  def serialize_agent(agent)
    {
      id: agent.id,
      name: agent.name,
      email: agent.email,
      avatar_url: agent.avatar_url
    }
  end

  def pagination_meta
    {
      current_page: params[:page] || 1,
      per_page: params[:per_page] || 50
    }
  end

  def check_authorization
    authorize(Conversation, :index?)
  end
end