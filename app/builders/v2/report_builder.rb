class V2::ReportBuilder
  include DateRangeHelper
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
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
         .group_by_day(:created_at, range: range, default_value: 0)
         .count
  end

  # unscoped removes all scopes added to a model previously
  def incoming_messages_count
    scope.messages.unscoped.where(account_id: account.id).incoming
         .group_by_day(:created_at, range: range, default_value: 0)
         .count
  end

  def outgoing_messages_count
    scope.messages.unscoped.where(account_id: account.id).outgoing
         .group_by_day(:created_at, range: range, default_value: 0)
         .count
  end

  def resolutions_count
    scope.conversations
         .resolved
         .group_by_day(:created_at, range: range, default_value: 0)
         .count
  end

  def avg_first_response_time
    scope.events
         .where(name: 'first_response')
         .group_by_day(:created_at, range: range, default_value: 0)
         .average(:value)
  end

  def avg_resolution_time
    scope.events.where(name: 'conversation_resolved')
         .group_by_day(:created_at, range: range, default_value: 0)
         .average(:value)
  end

  # Taking average of average is not too accurate
  # https://en.wikipedia.org/wiki/Simpson's_paradox
  # TODO: Will optimize this later
  def avg_resolution_time_summary
    return 0 if avg_resolution_time.values.empty?

    (avg_resolution_time.values.sum / avg_resolution_time.values.length)
  end

  def avg_first_response_time_summary
    return 0 if avg_first_response_time.values.empty?

    (avg_first_response_time.values.sum / avg_first_response_time.values.length)
  end
end
