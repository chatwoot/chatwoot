class Api::V1::Accounts::WhatsappTopupRequestsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @whatsapp_topup_requests = policy_scope(Current.account.whatsapp_topup_requests).order(created_at: :desc)
  end

  def create
    @whatsapp_topup_request = Current.account.whatsapp_topup_requests.create!(
      user: Current.user,
      credits: topup_request_params[:credits]
    )
  end

  private

  def check_authorization
    authorize(WhatsappTopupRequest)
  end

  def topup_request_params
    params.require(:whatsapp_topup_request).permit(:credits)
  end
end
