class Api::V1::Accounts::NotificationsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 15
  include DateRangeHelper

  before_action :fetch_notification, only: [:update, :destroy, :snooze, :unread]
  before_action :set_primary_actor, only: [:read_all]
  before_action :set_current_page, only: [:index]

  def index
    @notifications = notification_finder.notifications
    @unread_count = notification_finder.unread_count
    @count = notification_finder.count
  end

  def read_all
    # rubocop:disable Rails/SkipsModelValidations
    if @primary_actor
      current_user.notifications.where(account_id: current_account.id, primary_actor: @primary_actor, read_at: nil)
                  .update_all(read_at: DateTime.now.utc)
    else
      current_user.notifications.where(account_id: current_account.id, read_at: nil).update_all(read_at: DateTime.now.utc)
    end
    # rubocop:enable Rails/SkipsModelValidations
    head :ok
  end

  def update
    @notification.update(read_at: DateTime.now.utc)
    render json: @notification
  end

  def unread
    @notification.update(read_at: nil)
    render json: @notification
  end

  def destroy
    @notification.destroy
    head :ok
  end

  def destroy_all
    if params[:type] == 'read'
      ::Notification::DeleteNotificationJob.perform_later(Current.user, type: :read)
    else
      ::Notification::DeleteNotificationJob.perform_later(Current.user, type: :all)
    end
    head :ok
  end

  def unread_count
    @unread_count = notification_finder.unread_count
    render json: @unread_count
  end

  def snooze
    updated_meta = (@notification.meta || {}).merge('last_snoozed_at' => nil)
    @notification.update(snoozed_until: parse_date_time(params[:snoozed_until].to_s), meta: updated_meta) if params[:snoozed_until]
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

  def notification_finder
    @notification_finder ||= NotificationFinder.new(Current.user, Current.account, params)
  end
end
