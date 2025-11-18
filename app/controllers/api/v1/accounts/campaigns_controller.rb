class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def show
    @campaign_contacts_scope = @campaign.campaign_contacts.includes(:contact).order(created_at: :desc)
    @total_count = @campaign_contacts_scope.count
    @campaign_contacts = paginate_campaign_contacts(@campaign_contacts_scope)
    @pagination_meta = build_pagination_meta(@total_count)
  end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def update
    @campaign.update!(campaign_params)
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at, audience: [:type, :id], trigger_rules: {}, template_params: {})
  end

  def paginate_campaign_contacts(scope)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 25
    offset = (page - 1) * per_page
    scope.limit(per_page).offset(offset)
  end

  def build_pagination_meta(total_count)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 25
    {
      current_page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: (total_count.to_f / per_page).ceil
    }
  end
end
