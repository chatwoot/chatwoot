class V2::Reports::AgentSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    set_grouped_conversations_count
    set_grouped_avg_reply_time
    set_grouped_avg_first_response_time
    set_grouped_avg_resolution_time
    prepare_report
  end

  private

  def set_grouped_conversations_count
    @grouped_conversations_count = Current.account.conversations.where(created_at: range).group('assignee_id').count
  end

  def set_grouped_avg_resolution_time
    @grouped_avg_resolution_time = get_grouped_average(reporting_events.where(name: 'conversation_resolved'))
  end

  def set_grouped_avg_first_response_time
    @grouped_avg_first_response_time = get_grouped_average(reporting_events.where(name: 'first_response'))
  end

  def set_grouped_avg_reply_time
    @grouped_avg_reply_time = get_grouped_average(reporting_events.where(name: 'reply_time'))
  end

  def group_by_key
    :user_id
  end

  def reporting_events
    @reporting_events ||= Current.account.reporting_events.where(created_at: range)
  end

  def prepare_report
    account.account_users.each_with_object([]) do |account_user, arr|
      arr << {
        id: account_user.user_id,
        conversations_count: @grouped_conversations_count[account_user.user_id],
        avg_resolution_time: @grouped_avg_resolution_time[account_user.user_id],
        avg_first_response_time: @grouped_avg_first_response_time[account_user.user_id],
        avg_reply_time: @grouped_avg_reply_time[account_user.user_id]
      }
    end
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]).present? ? :value_in_business_hours : :value
  end
end
