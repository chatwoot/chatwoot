class Api::V1::Accounts::MarketingCampaignsController < Api::V1::Accounts::BaseController
  before_action :set_marketing_campaign, only: [:show, :update, :destroy]

  def index
    @marketing_campaigns = current_account.marketing_campaigns
  end

  def show; end

  def create
    @marketing_campaign = current_account.marketing_campaigns.new(marketing_campaign_params)
    if @marketing_campaign.save
      render :show
    else
      render json: { errors: @marketing_campaign.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @marketing_campaign.update(marketing_campaign_params)
      render :show
    else
      render json: { errors: @marketing_campaign.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @marketing_campaign.destroy
    head :no_content
  end

  private

  def set_marketing_campaign
    @marketing_campaign = current_account.marketing_campaigns.find(params[:id])
  end

  def marketing_campaign_params
    params.require(:marketing_campaign).permit(:title, :description, :start_date, :end_date, :source_id)
  end
end
