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
    send(params[:metric])
  end

  # For backward compatible with old report
  def build
    if %w[avg_first_response_time avg_resolution_time].include?(params[:metric])
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
      conversations_count: conversations_count.values.sum,
      incoming_messages_count: incoming_messages_count.values.sum,
      outgoing_messages_count: outgoing_messages_count.values.sum,
      avg_first_response_time: avg_first_response_time_summary,
      avg_resolution_time: avg_resolution_time_summary,
      resolutions_count: resolutions_count.values.sum
    }
  end

  def conversation_metrics
    if params[:type].equal?(:account)
      conversations
    else
      agent_metrics.sort_by { |hash| hash[:metric][:open] }.reverse
    end
  end

  private

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
      permit: %w[day week month year],
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
        metric: conversations
      }
    end
  end

  def conversations
    @open_conversations = scope.conversations.where(account_id: @account.id).open
    first_response_count = scope.reporting_events.where(name: 'first_response', conversation_id: @open_conversations.pluck('id')).count
    metric = {
      open: @open_conversations.count,
      unattended: @open_conversations.count - first_response_count
    }
    metric[:unassigned] = @open_conversations.unassigned.count if params[:type].equal?(:account)
    metric
  end
end
