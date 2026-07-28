class Api::V1::Accounts::Inboxes::WidgetAnnouncementsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :fetch_announcement, only: [:update, :destroy]
  before_action -> { check_authorization(WidgetAnnouncement) }

  def index
    @announcements = @inbox.widget_announcements.order(created_at: :desc)
  end

  def create
    @announcement = @inbox.widget_announcements.create!(
      announcement_params.merge(account_id: Current.account.id)
    )
  end

  def update
    @announcement.update!(announcement_params)
  end

  def destroy
    @announcement.destroy!
    head :ok
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def fetch_announcement
    @announcement = @inbox.widget_announcements.find(params[:id])
  end

  def announcement_params
    params.require(:widget_announcement).permit(:title, :message, :level, :action_url, :starts_at, :ends_at, :enabled)
  end
end
