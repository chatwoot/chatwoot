class Api::V1::Accounts::Contacts::ConversationPlansController < Api::V1::Accounts::Contacts::BaseController
  before_action :conversation_plan, except: [:index]

  def index
    @conversation_plans = @contact.conversation_plans.includes(:conversation)
  end

  def complete
    @conversation_plan.update!(completed_at: Time.current)
  end

  private

  def conversation_plan
    @conversation_plan ||= @contact.conversation_plans.find(params[:id])
  end
end
