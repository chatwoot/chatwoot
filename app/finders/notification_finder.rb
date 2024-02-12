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
    status = params[:status]
    type = params[:type]
    # Return all the notifications
    return if status == 'snoozed' && type == 'read'

    if type == 'read' || status == 'snoozed'
      exclude_both_snoozed_and_read
    else
      # Default case: return all the unread notifications
      include_unread
    end
  end

  def exclude_both_snoozed_and_read
    @notifications = @notifications.where.not('snoozed_until IS NOT NULL AND read_at IS NOT NULL')
  end

  def include_unread
    @notifications = @notifications.where(read_at: nil)
  end

  def current_page
    params[:page] || 1
  end

  def notifications
    @notifications.page(current_page).per(RESULTS_PER_PAGE).order(last_activity_at: params[:sort_order] || :desc)
  end
end
