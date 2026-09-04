class Api::V1::Accounts::Conversations::ContactInfoRequestsController < Api::V1::Accounts::Conversations::BaseController
  def create
    @message = Whatsapp::ContactInfoRequestService.new(conversation: @conversation, sender: Current.user).perform
    render 'api/v1/accounts/conversations/messages/create'
  rescue CustomExceptions::WhatsappContactInfoRequestError => e
    render json: { error: e.message }, status: e.http_status
  end
end
