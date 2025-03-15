class Api::V1::Widget::CampaignsController < Api::V1::Widget::BaseController
  skip_before_action :set_contact

  def index
    @campaigns = @web_widget
                 .inbox
                 .campaigns
                 .where(enabled: true, account_id: @web_widget.inbox.account_id)
                 .includes(:sender)
  end
end
