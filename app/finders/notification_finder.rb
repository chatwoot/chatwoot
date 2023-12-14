class NotificationFinder
  attr_reader :current_user, :current_account, :params

  RESULTS_PER_PAGE = 15

  def initialize(current_user, current_account, params)
    @current_user = current_user
    @current_account = current_account
    @params = params
  end

  def perform
    set_up
    notifications
  end

  private

  def set_up
    find_all_notifications
    filter_by_status if params[:status] == 'snoozed'
  end

  def find_all_notifications
    @notifications = current_user.notifications.where(account_id: @current_account.id)
  end

  def filter_by_status
    @notifications = @notifications.where('snoozed_until > ?', DateTime.now.utc)
    @notifications
  end

  def current_page
    params[:page] || 1
  end

  def notifications
    @notifications.page(current_page).per(RESULTS_PER_PAGE).order(updated_at: :desc)
  end
end
