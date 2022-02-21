class V2::ReportBuilder
  include DateRangeHelper
  attr_reader :account, :params

  DEFAULT_GROUP_BY = 'day'.freeze

  def initialize(account, params)
    @account = account
    @params = params

    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]
  end

  def timeseries
    send(params[:metric])
  end

  # For backward compatible with old report
  def build
    timeseries.each_with_object([]) do |p, arr|
      arr << { value: p[1], timestamp: p[0].to_time.to_i }
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

  def conversations_count
    scope.conversations
         .group_by_period(params[:group_by] || DEFAULT_GROUP_BY,
                          :created_at, range: range, default_value: 0, permit: %w[day week month year],
                                       time_zone: @timezone)
         .count
  end

  def incoming_messages_count
    scope.messages.incoming.unscope(:order)
         .group_by_period(params[:group_by] || DEFAULT_GROUP_BY,
                          :created_at, range: range, default_value: 0, permit: %w[day week month year],
                                       time_zone: @timezone)
         .count
  end

  def outgoing_messages_count
    scope.messages.outgoing.unscope(:order)
         .group_by_period(params[:group_by] || DEFAULT_GROUP_BY,
                          :created_at, range: range, default_value: 0, permit: %w[day week month year],
                                       time_zone: @timezone)
         .count
  end

  def resolutions_count
    scope.conversations
         .resolved
         .group_by_period(params[:group_by] || DEFAULT_GROUP_BY,
                          :created_at, range: range, default_value: 0, permit: %w[day week month year],
                                       time_zone: @timezone)
         .count
  end

  def avg_first_response_time
    scope.events
         .where(name: 'first_response', created_at: range)
         .average(:value)
  end

  def avg_resolution_time
    scope.events.where(name: 'conversation_resolved', created_at: range)
         .average(:value)
  end

  def avg_resolution_time_summary
    return 0 if avg_resolution_time.blank?

    avg_resolution_time
  end

  def avg_first_response_time_summary
    return 0 if avg_first_response_time.blank?

    avg_first_response_time
  end
end
