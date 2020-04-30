class Api::V1::Accounts::NotificationsController < Api::BaseController
  protect_from_forgery with: :null_session

  before_action :fetch_notification, only: [:update]

  def index
    @notifications = current_user.notifications.where(account_id: current_account.id)
    render json: @notifications
  end

  def update
    @notification.update(read_at: DateTime.now.utc)
    render json: @notification
  end

  private

  def fetch_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
