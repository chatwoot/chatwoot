class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def destroy
    @campaign.destroy
    head :ok
  end

  def show; end

  def update
    @campaign.update(campaign_params)
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :inbox_id, :sender_id, trigger_rules: {})
  end
end
