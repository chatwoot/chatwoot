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
  # calls they handled within conversations they can still access.
  def filter_by_visibility
    return if account_wide_access?

    @calls = @calls.where(accepted_by_agent_id: @current_user.id, conversation_id: accessible_conversations)
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
    @calls.includes(:contact, :inbox, :conversation, :accepted_by_agent)
          .order(created_at: :desc)
          .page(@params[:page] || 1)
          .per(RESULTS_PER_PAGE)
  end
end
