class Api::V1::Accounts::Contacts::ConversationPlansController < Api::V1::Accounts::Contacts::BaseController
  def index
    @conversation_plans = @contact.conversation_plans.includes(:conversation)
  end
end
