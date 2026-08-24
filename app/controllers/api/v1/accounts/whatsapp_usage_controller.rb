class Api::V1::Accounts::WhatsappUsageController < Api::V1::Accounts::BaseController
  before_action :ensure_administrator

  def show
    @summary = Whatsapp::UsageSummaryService.new(account: Current.account).summary
  end

  private

  def ensure_administrator
    raise Pundit::NotAuthorizedError unless Current.user.administrator?
  end
end
