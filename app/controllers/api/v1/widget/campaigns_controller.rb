class Api::V1::Widget::CampaignsController < Api::V1::Widget::BaseController
  skip_before_action :set_contact

  def index
    account = @web_widget.inbox.account
    @campaigns = if account.feature_enabled?('campaigns')
                   @web_widget
                     .inbox
                     .campaigns
                     .where(enabled: true, account_id: account.id)
                     .includes(:sender)
                 else
                   []
                 end
  end
end
