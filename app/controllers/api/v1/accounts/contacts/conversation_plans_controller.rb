class Api::V1::Accounts::Contacts::ConversationPlansController < Api::V1::Accounts::Contacts::BaseController
  before_action :conversation_plan, except: [:index]

  def index
    @conversation_plans = @contact.conversation_plans.includes(:conversation).latest
  end

  def complete
    @conversation_plan.update!(completed_at: Time.current)
    # Restrict job that reopen snoozed conversations
    @conversation = @conversation_plan.conversation
    @conversation.update!(snoozed_until: nil, status: :resolved)
  end

  private

  def conversation_plan
    @conversation_plan ||= @contact.conversation_plans.find(params[:id])
  end
end
