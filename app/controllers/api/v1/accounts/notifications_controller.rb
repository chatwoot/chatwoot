class Api::V1::Accounts::NotificationsController < Api::V1::Accounts::BaseController
  protect_from_forgery with: :null_session

  before_action :fetch_notification, only: [:update]

  def index
    @unread_count = current_user.notifications.where(account_id: current_account.id, read_at: nil).count
    @notifications = current_user.notifications.where(account_id: current_account.id).page params[:page]
  end

  def read_all
    current_user.notifications.where(account_id: current_account.id, read_at: nil).update(read_at: DateTime.now.utc)
    head :ok
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
