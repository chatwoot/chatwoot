class NotificationFinder
  attr_reader :current_user, :current_account, :params

  RESULTS_PER_PAGE = 15

  def initialize(current_user, current_account, params = {})
    @current_user = current_user
    @current_account = current_account
    @params = params
    set_up
  end

  def perform
    notifications
  end

  def unread_count
    @notifications.where(read_at: nil).count
  end

  def count
    @notifications.count
  end

  private

  def set_up
    find_all_notifications
    apply_filters
  end

  def find_all_notifications
    @notifications = current_user.notifications.where(account_id: @current_account.id)
  end

  def apply_filters
    # REturn all the read, unread and snoozed notifications when the status is snoozed and type is read
    return if params[:status] == 'snoozed' && params[:type] == 'read'

    # Exclude snoozed notifications when the status is not snoozed and type is read
    if params[:type] == 'read' && params[:status] != 'snoozed'
      exclude_snoozed
      return
    end
    # Exclude read notifications when the status is snoozed and type is not read
    if params[:status] == 'snoozed' && params[:type] != 'read'
      exclude_read
      return
    end
    # Return only unread notifications when params are not passed
    exclude_snoozed
    exclude_read
  end

  def include_unread
    @notifications = @notifications.where(read_at: nil)
  end

  def exclude_read
    @notifications = @notifications.where(read_at: nil)
  end

  def exclude_snoozed
    @notifications = @notifications.where(snoozed_until: nil)
  end

  def current_page
    params[:page] || 1
  end

  def notifications
    @notifications.page(current_page).per(RESULTS_PER_PAGE).order(last_activity_at: params[:sort_order] || :desc)
  end
end
