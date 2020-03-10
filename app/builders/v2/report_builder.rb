class V2::ReportBuilder
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def timeseries
    send(params[:metric])
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
end
