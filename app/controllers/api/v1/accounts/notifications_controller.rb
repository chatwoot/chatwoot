class Api::V1::Accounts::NotificationsController < Api::V1::Accounts::BaseController
  protect_from_forgery with: :null_session

  before_action :fetch_notification, only: [:update]
  before_action :set_primary_actor, only: [:read_all]
  before_action :set_current_page, only: [:index]

  def index
    @unread_count = current_user.notifications.where(account_id: current_account.id, read_at: nil).count
    @count = notifications.count
    @notifications = notifications.page @current_page
  end

  def read_all
    if @primary_actor
      current_user.notifications.where(account_id: current_account.id, primary_actor: @primary_actor, read_at: nil)
                  .update(read_at: DateTime.now.utc)
    else
      current_user.notifications.where(account_id: current_account.id, read_at: nil).update(read_at: DateTime.now.utc)
    end

    head :ok
  end

  def update
    @notification.update(read_at: DateTime.now.utc)
    render json: @notification
  end

  private

  def set_primary_actor
    return unless params[:primary_actor_type]
    return unless Notification::PRIMARY_ACTORS.include?(params[:primary_actor_type])

    @primary_actor = params[:primary_actor_type].safe_constantize.find_by(id: params[:primary_actor_id])
  end

  def fetch_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def notifications
    @notifications ||= current_user.notifications.where(account_id: current_account.id)
  end
end
