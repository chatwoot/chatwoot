class CallFinder
  RESULTS_PER_PAGE = 25

  def initialize(current_user, current_account, params)
    @current_user = current_user
    @current_account = current_account
    @params = params
  end

  def perform
    @calls = @current_account.calls
    filter_by_visibility
    filter_by_status
    filter_by_direction
    filter_by_inbox
    filter_by_agent
    filter_by_date_range

    { calls: paginated_calls, count: @calls.count }
  end

  private

  # Admins and report managers see the whole account; everyone else only sees
  # calls they handled within conversations they can still access, plus, when asking
  # for ringing calls, the ones still waiting for them to answer.
  def filter_by_visibility
    return if account_wide_access?

    own = @calls.where(accepted_by_agent_id: @current_user.id, conversation_id: accessible_conversations)
    @calls = ringing_requested? ? own.or(ringing_for_current_user) : own
  end

  # An unanswered inbound call is visible to the agents it can ring: the assignee if the
  # conversation has one, otherwise the inbox's members. A phone that lost its socket
  # asks for these on launch and on return to the foreground.
  def ringing_for_current_user
    @calls.where(status: 'ringing', accepted_by_agent_id: nil, direction: :incoming)
          .where(inbox_id: @current_user.inboxes.where(account_id: @current_account.id).select(:id))
          .where(conversation_id: @current_account.conversations.where(assignee_id: [nil, @current_user.id]).select(:id))
  end

  def ringing_requested?
    @params[:status].present? && Call.status_from_display(@params[:status]) == 'ringing'
  end

  def accessible_conversations
    Conversations::PermissionFilterService.new(@current_account.conversations, @current_user, @current_account).perform.select(:id)
  end

  def account_wide_access?
    account_user = Current.account_user
    account_user&.administrator? || account_user&.custom_role&.permissions&.include?('report_manage')
  end

  def filter_by_status
    @calls = @calls.where(status: Call.status_from_display(@params[:status])) if @params[:status].present?
  end

  def filter_by_direction
    @calls = @calls.where(direction: Call.direction_from_label(@params[:direction])) if @params[:direction].present?
  end

  def filter_by_inbox
    @calls = @calls.where(inbox_id: @params[:inbox_id]) if @params[:inbox_id].present?
  end

  def filter_by_agent
    @calls = @calls.where(accepted_by_agent_id: @params[:agent_id]) if @params[:agent_id].present?
  end

  # since/until are unix timestamps, matching DateRangeHelper conventions.
  def filter_by_date_range
    return if @params[:since].blank? || @params[:until].blank?

    @calls = @calls.where(created_at: Time.zone.at(@params[:since].to_i)..Time.zone.at(@params[:until].to_i))
  end

  def paginated_calls
    @calls.includes(:contact, :conversation, :accepted_by_agent, inbox: :channel)
          .order(created_at: :desc)
          .page(@params[:page] || 1)
          .per(RESULTS_PER_PAGE)
  end
end
