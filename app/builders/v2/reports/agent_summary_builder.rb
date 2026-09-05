class V2::Reports::AgentSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time,
              :agent_chat_duration, :csat_satisfaction_score

  def load_data
    super
    @agent_chat_duration = fetch_agent_chat_duration
  end

  def fetch_conversations_count
    filtered_conversations.group('assignee_id').count
  end

  def fetch_agent_chat_duration
    scope = account.reporting_events.where(name: :agent_chat_duration, created_at: range)
    scope = apply_filters(scope)
    scope.group(:user_id).average(:value)
  end

  def prepare_report
    scope = filter_agent_scope

    scope.map do |account_user|
      build_agent_stats(account_user)
    end
  end

  def filter_agent_scope
    scope = account.account_users

    if params[:user_ids].present? && params[:user_ids].reject(&:blank?).any?
      scope.where(user_id: params[:user_ids].reject(&:blank?))
    elsif cross_filters?(:user_ids)
      apply_agent_cross_filter_scope(scope)
    else
      scope
    end
  end

  def apply_agent_cross_filter_scope(scope)
    all_user_ids = collect_all_user_ids
    return [] if all_user_ids.empty?

    scope.where(user_id: all_user_ids)
  end

  def collect_all_user_ids
    [
      conversations_count.keys,
      resolved_count.keys,
      avg_resolution_time.keys,
      avg_first_response_time.keys,
      avg_reply_time.keys,
      agent_chat_duration.keys,
      csat_satisfaction_score.keys
    ].flatten.compact.uniq
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
      agent_chat_duration: (agent_chat_duration[user_id] || 0).to_i,
      csat_satisfaction_score: csat_satisfaction_score[user_id] || 0
    }
  end

  def apply_csat_filters(scope)
    scope = apply_csat_user_filter(scope)
    scope = scope.joins(:conversation)
    scope = apply_csat_inbox_filter(scope)
    scope = apply_csat_team_filter(scope)
    apply_csat_label_filter(scope)
  end

  def apply_csat_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope.where(assigned_agent_id: params[:user_ids].reject(&:blank?))
  end

  def apply_csat_inbox_filter(scope)
    return scope if params[:inbox_ids].blank?

    scope.where(conversations: { inbox_id: params[:inbox_ids].reject(&:blank?) })
  end

  def apply_csat_team_filter(scope)
    return scope if params[:team_ids].blank?

    scope.where(conversations: { team_id: params[:team_ids].reject(&:blank?) })
  end

  def apply_csat_label_filter(scope)
    return scope if params[:label_ids].blank?

    tag_ids = ReportingEvent.tag_ids_for_labels(params[:label_ids].reject(&:blank?), account.id)
    return scope if tag_ids.empty?

    scope.joins(conversation_labels_join_clause).where(taggings: { tag_id: tag_ids })
  end

  def conversation_labels_join_clause
    <<~SQL.squish
      INNER JOIN taggings
        ON taggings.taggable_id = conversations.id
        AND taggings.taggable_type = 'Conversation'
        AND taggings.context = 'labels'
    SQL
  end

  def csat_group_by_key
    'csat_survey_responses.assigned_agent_id'
  end

  def group_by_key
    :user_id
  end
end
