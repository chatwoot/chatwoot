class Conversations::ConversationPlanBuilder
  attr_reader :conversation_plan

  def initialize(user, conversation, params)
    @params = params
    @conversation = conversation
    @user = user
  end

  def perform
    @conversation_plan = @conversation.conversation_plans.build(conversation_plan_params)
    @conversation_plan.save!
    @conversation_plan
  end

  private

  def conversation_plan_params
    {
      conversation_id: @conversation.id,
      account_id: @conversation.account_id,
      created_by_id: @user&.id,
      contact_id: @conversation.contact_id,
      description: @params[:description],
      snoozed_until: @conversation.snoozed_until
    }
  end
end
