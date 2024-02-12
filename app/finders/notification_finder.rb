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

    if type == 'read'
      # Exclude snoozed notifications when type is 'read' and status is not 'snoozed'
      exclude_snoozed
    elsif status == 'snoozed'
      # Exclude read notifications when status is 'snoozed' and type is not 'read'
      exclude_read
    else
      # Default case: Exclude both snoozed and read notifications
      # This handles the case where neither 'type' nor 'status' are provided in params
      exclude_snoozed
      exclude_read
    end
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
