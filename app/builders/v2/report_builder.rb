class V2::ReportBuilder
  include DateRangeHelper
  attr_reader :account, :params

  DEFAULT_GROUP_BY = 'day'.freeze

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
    timeseries.each_with_object([]) do |p, arr|
      arr << { value: p[1], timestamp: p[0].in_time_zone(@timezone).to_i }
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

  private

  def scope
    case params[:type]
    when :account
      account
    when :inbox
      inbox
    when :agent
      user
    when :label
      label
    when :team
      team
    end
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
    object_scope.group_by_period(
      params[:group_by] || DEFAULT_GROUP_BY,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year],
      time_zone: @timezone
    )
  end

  def conversations_count
    (get_grouped_values scope.conversations).count
  end

  def incoming_messages_count
    (get_grouped_values scope.messages.incoming.unscope(:order)).count
  end

  def outgoing_messages_count
    (get_grouped_values scope.messages.outgoing.unscope(:order)).count
  end

  def resolutions_count
    (get_grouped_values scope.conversations.resolved).count
  end

  def avg_first_response_time
    (get_grouped_values scope.reporting_events.where(name: 'first_response')).average(:value)
  end

  def avg_resolution_time
    (get_grouped_values scope.reporting_events.where(name: 'conversation_resolved')).average(:value)
  end

  def avg_resolution_time_summary
    avg_rt = scope.reporting_events
                  .where(name: 'conversation_resolved', created_at: range)
                  .average(:value)

    return 0 if avg_rt.blank?

    avg_rt
  end

  def avg_first_response_time_summary
    avg_frt = scope.reporting_events
                   .where(name: 'first_response', created_at: range)
                   .average(:value)

    return 0 if avg_frt.blank?

    avg_frt
  end
end
