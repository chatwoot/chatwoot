class V2::ReportBuilder
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def timeseries
    send(params[:metric])
  end

  # Formatting response to make backward compatible with old report implementation
  def formatted_timeseries
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
    return account if params[:type].match?('account')
    return inbox if params[:type].match?('inbox')
    return user if params[:type].match?('agent')
  end

  def inbox
    @inbox ||= account.inboxes.where(id: params[:id]).first
  end

  def user
    @user ||= account.users.where(id: params[:id]).first
  end

  def conversations_count
    scope.conversations
         .group_by_day(:created_at, range: range, series: false)
         .count
  end

  def incoming_messages_count
    scope.messages.unscoped.incoming
         .group_by_day(:created_at, range: range, series: false)
         .count
  end

  def outgoing_messages_count
    scope.messages.unscoped.outgoing
         .group_by_day(:created_at, range: range, series: false)
         .count
  end

  def resolutions_count
    scope.conversations
         .resolved
         .group_by_day(:created_at, range: range, series: false)
         .count
  end

  def avg_first_response_time
    scope.events
         .where(name: 'first_response')
         .group_by_day(:created_at, range: range, series: false)
         .median(:value)
  end

  def avg_resolution_time
    scope.events.where(name: 'conversation_resolved')
         .group_by_day(:created_at, range: range, series: false)
         .median(:value)
  end

  def range
    params[:since]..params[:until]
  end

  def avg_resolution_time_summary
    return 0 if avg_resolution_time.values.empty?

    (avg_first_response_time.values.sum / avg_first_response_time.values.length)
  end

  def avg_first_response_time_summary
    return 0 if avg_first_response_time.values.empty?

    (avg_first_response_time.values.sum / avg_first_response_time.values.length)
  end
end
