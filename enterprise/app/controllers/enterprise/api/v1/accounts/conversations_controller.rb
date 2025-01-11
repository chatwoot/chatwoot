module Enterprise::Api::V1::Accounts::ConversationsController
  extend ActiveSupport::Concern
  included do
    before_action :set_assistant, only: [:copilot]
  end

  def copilot
    assistant = @conversation.inbox.captain_assistant
    return render json: { message: I18n.t('captain.copilot_error') } unless assistant

    response = Captain::Copilot::ChatService.new(
      assistant,
      messages: copilot_params[:previous_messages],
      conversation_history: @conversation.to_llm_text
    ).execute(copilot_params[:message])

    render json: { message: response }
  end

  def permitted_update_params
    super.merge(params.permit(:sla_policy_id))
  end

  private

  def copilot_params
    params.permit(:previous_messages, :message, :assistant_id)
  end
end
