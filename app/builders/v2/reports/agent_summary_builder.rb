class V2::Reports::AgentSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time,
              :agent_chat_duration

  def load_data
    super
    @agent_chat_duration = fetch_agent_chat_duration
  end

  def fetch_conversations_count
    scope = account.conversations.where(created_at: range)
    scope = scope.where(assignee_id: params[:user_ids]&.reject(&:blank?)) if params[:user_ids].present?
    scope = scope.where(inbox_id: params[:inbox_ids]&.reject(&:blank?)) if params[:inbox_ids].present?
    scope = scope.where(team_id: params[:team_ids]&.reject(&:blank?)) if params[:team_ids].present?
    scope.group('assignee_id').count
  end

  def fetch_agent_chat_duration
    scope = account.reporting_events
           .where(name: :agent_chat_duration, created_at: range)
           .filter_by_user_id(params[:user_ids]&.reject(&:blank?))
    
    scope = scope.filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?)) if params[:inbox_ids].present?
    scope = filter_by_team(scope) if params[:team_ids].present?
    
    scope.group(:user_id).average(:value)
  end

  def prepare_report
    scope = account.account_users
    
    if params[:user_ids].present? && params[:user_ids].reject(&:blank?).any?
      scope = scope.where(user_id: params[:user_ids].reject(&:blank?))
    else
      if params[:inbox_ids].present? || params[:team_ids].present?
        all_user_ids = [
          conversations_count.keys,
          resolved_count.keys,
          avg_resolution_time.keys,
          avg_first_response_time.keys,
          avg_reply_time.keys,
          agent_chat_duration.keys
        ].flatten.compact.uniq
        
        return [] if all_user_ids.empty?
        scope = scope.where(user_id: all_user_ids)
      end
    end
    
    scope.map do |account_user|
      build_agent_stats(account_user)
    end
  end

  def build_agent_stats(account_user)
    user_id = account_user.user_id
    {
      id: user_id,
      conversations_count: conversations_count[user_id] || 0,
      resolved_conversations_count: resolved_count[user_id] || 0,
      avg_resolution_time: avg_resolution_time[user_id],
      avg_first_response_time: avg_first_response_time[user_id],
      avg_reply_time: avg_reply_time[user_id],
      agent_chat_duration: (agent_chat_duration[user_id] || 0).to_i
    }
  end

  def group_by_key
    :user_id
  end
end
