class Api::V1::Widget::CampaignsController < Api::V1::Widget::BaseController
  skip_before_action :set_contact

  def index
    @campaigns = @web_widget.inbox.campaigns.where(enabled: true)
  end

  private

  def permitted_params
    params.permit(:website_token)
  end
end
