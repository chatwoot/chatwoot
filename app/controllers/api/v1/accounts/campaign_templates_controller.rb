class Api::V1::Accounts::CampaignTemplatesController < Api::V1::Accounts::BaseController
  before_action :campaign_template, except: [:index, :create]
  before_action :check_authorization

  def index
    @campaign_templates = Current.account.campaign_templates.order(created_at: :desc)
  end

  def show; end

  def create
    @campaign_template = Current.account.campaign_templates.create!(campaign_template_params)
  end

  def update
    @campaign_template.update!(campaign_template_params)
  end

  def destroy
    @campaign_template.destroy!
    head :ok
  end

  private

  def campaign_template
    @campaign_template ||= Current.account.campaign_templates.find(params[:id])
  end

  def campaign_template_params
    params.require(:campaign_template).permit(:name, :body)
  end
end
