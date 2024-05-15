class V2::ReportBuilder
  include DateRangeHelper
  include ReportHelper
  attr_reader :account, :params

  DEFAULT_GROUP_BY = 'day'.freeze
  AGENT_RESULTS_PER_PAGE = 25

  def initialize(account, params)
    @account = account
    @params = params

    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]&.name
  end

  def timeseries
    return send(params[:metric]) if metric_valid?

    Rails.logger.error "ReportBuilder: Invalid metric - #{params[:metric]}"
    {}
  end

  # For backward compatible with old report
  def build
    if %w[avg_first_response_time avg_resolution_time reply_time].include?(params[:metric])
      timeseries.each_with_object([]) do |p, arr|
        arr << { value: p[1], timestamp: p[0].in_time_zone(@timezone).to_i, count: @grouped_values.count[p[0]] }
      end
    else
      timeseries.each_with_object([]) do |p, arr|
        arr << { value: p[1], timestamp: p[0].in_time_zone(@timezone).to_i }
      end
    end
  end

  def summary
    {
      conversations_count: conversations.count,
      incoming_messages_count: incoming_messages.count,
      outgoing_messages_count: outgoing_messages.count,
      avg_first_response_time: avg_first_response_time_summary,
      avg_resolution_time: avg_resolution_time_summary,
      resolutions_count: resolutions.count,
      reply_time: reply_time_summary
    }
  end

  def short_summary
    {
      conversations_count: conversations.count,
      avg_first_response_time: avg_first_response_time_summary,
      avg_resolution_time: avg_resolution_time_summary
    }
  end

  def bot_summary
    {
      bot_resolutions_count: bot_resolutions.count,
      bot_handoffs_count: bot_handoffs.count
    }
  end

  def conversation_metrics
    if params[:type].equal?(:account)
      live_conversations
    else
      agent_metrics.sort_by { |hash| hash[:metric][:open] }.reverse
    end
  end

  private

  def metric_valid?
    %w[conversations_count
       incoming_messages_count
       outgoing_messages_count
       avg_first_response_time
       avg_resolution_time reply_time
       resolutions_count
       bot_resolutions_count
       bot_handoffs_count
       reply_time].include?(params[:metric])
  end

  def inbox
    @inbox ||= account.inboxes.find(params[:id])
  end

  def user
    @user ||= account.users.find(params[:id])
  end

  def label
    @label ||= account.labels.find(params[:id])
  end

  def team
    @team ||= account.teams.find(params[:id])
  end

  def get_grouped_values(object_scope)
    @grouped_values = object_scope.group_by_period(
      params[:group_by] || DEFAULT_GROUP_BY,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: @timezone
    )
  end

  def agent_metrics
    account_users = @account.account_users.page(params[:page]).per(AGENT_RESULTS_PER_PAGE)
    account_users.each_with_object([]) do |account_user, arr|
      @user = account_user.user
      arr << {
        id: @user.id,
        name: @user.name,
        email: @user.email,
        thumbnail: @user.avatar_url,
        availability: account_user.availability_status,
        metric: live_conversations
      }
    end
  end

  def live_conversations
    @open_conversations = scope.conversations.where(account_id: @account.id).open
    metric = {
      open: @open_conversations.count,
      unattended: @open_conversations.unattended.count
    }
    metric[:unassigned] = @open_conversations.unassigned.count if params[:type].equal?(:account)
    metric[:pending] = @open_conversations.pending.count if params[:type].equal?(:account)
    metric
  end
end
