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
    filter_by_notification_settings
    filter_by_status
  end

  def find_all_notifications
    @notifications = current_user.notifications.where(account_id: @current_account.id)
  end

  def filter_by_notification_settings
    notification_settings = current_user.notification_settings.find_by(account_id: @current_account.id)
    subscribed_notification_types = get_subscribed_notification_types(notification_settings)
    @notifications = filter_notifications_by_types(@notifications, subscribed_notification_types)
  end

  def get_subscribed_notification_types(notification_settings)
    subscribed_notification_types = []
    return subscribed_notification_types if notification_settings.blank?

    ::Notification::NOTIFICATION_TYPES.each_key do |notification_type|
      email_flag = "email_#{notification_type}".to_sym
      push_flag = "push_#{notification_type}".to_sym

      if notification_settings.public_send(email_flag) || notification_settings.public_send(push_flag)
        subscribed_notification_types << notification_type
      end
    end

    subscribed_notification_types
  end

  def filter_notifications_by_types(notifications, types)
    notifications.where(notification_type: types)
  end

  def filter_by_status
    @notifications = @notifications.where('snoozed_until > ?', DateTime.now.utc) if params[:status] == 'snoozed'
  end

  def current_page
    params[:page] || 1
  end

  def notifications
    @notifications.page(current_page).per(RESULTS_PER_PAGE).order(last_activity_at: :desc)
  end
end
