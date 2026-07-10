class Api::V1::Accounts::CtwaTrackedLinksController < Api::V1::Accounts::BaseController
  before_action :fetch_tracked_link, only: [:destroy]

  def index
    authorize ::Inbox, :campaigns?

    render json: { payload: tracked_links.map { |tracked_link| tracked_link_payload(tracked_link) } }
  end

  def create
    inbox = Current.account.inboxes.find(tracked_link_params[:inbox_id])
    authorize inbox, :campaigns?

    tracked_link = Ctwa::TrackedLink.create!(
      account: Current.account,
      inbox: inbox,
      name: tracked_link_params[:name],
      prefilled_text: tracked_link_params[:prefilled_text]
    )

    render json: { payload: tracked_link_payload(tracked_link) }, status: :created
  end

  def destroy
    authorize @tracked_link.inbox, :campaigns?

    @tracked_link.destroy!
    head :no_content
  end

  private

  def tracked_links
    Ctwa::TrackedLink.where(account_id: Current.account.id).order(id: :desc)
  end

  def fetch_tracked_link
    @tracked_link = Ctwa::TrackedLink.where(account_id: Current.account.id).find(params[:id])
  end

  def tracked_link_params
    source_params = params[:ctwa_tracked_link].presence || params
    source_params.permit(:name, :inbox_id, :prefilled_text)
  end

  def tracked_link_payload(tracked_link)
    {
      id: tracked_link.id,
      name: tracked_link.name,
      code: tracked_link.code,
      prefilled_text: tracked_link.prefilled_text,
      clicks_count: tracked_link.clicks_count,
      conversations_count: tracked_link.conversations_count,
      inbox_id: tracked_link.inbox_id,
      wa_link: tracked_link.wa_link,
      short_url: short_url_for(tracked_link)
    }
  end

  def short_url_for(tracked_link)
    "#{ENV.fetch('FRONTEND_URL', '').to_s.chomp('/')}/l/#{tracked_link.code}"
  end
end
