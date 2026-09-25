class Api::V1::Accounts::Conversations::ContactInfoRequestsController < Api::V1::Accounts::Conversations::BaseController
  rescue_from CustomExceptions::WhatsappContactInfoRequestError do |error|
    render json: { error: error.message }, status: error.http_status
  end

  def show
    render json: Whatsapp::ContactInfoRequestEligibilityService.new(conversation: @conversation).availability
  end

  def create
    @message = Whatsapp::ContactInfoRequestService.new(conversation: @conversation, sender: Current.user).perform
    render 'api/v1/accounts/conversations/messages/create'
  end
end
