module Enterprise::Api::V1::Accounts::ConversationsController
  extend ActiveSupport::Concern
  included do
    before_action :set_assistant, only: [:copilot]
  end

  def copilot
    # First try to get the user's preferred assistant from UI settings or from the request
    assistant_id = copilot_params[:assistant_id] || current_user.ui_settings&.dig('preferred_captain_assistant_id')

    # Find the assistant either by ID or from inbox
    assistant = if assistant_id.present?
                  Captain::Assistant.find_by(id: assistant_id, account_id: Current.account.id)
                else
                  @conversation.inbox.captain_assistant
                end

    return render json: { message: I18n.t('captain.copilot_error') } unless assistant

    response = Captain::Copilot::ChatService.new(
      assistant,
      previous_messages: copilot_params[:previous_messages],
      conversation_history: @conversation.to_llm_text,
      language: @conversation.account.locale_english_name
    ).generate_response(copilot_params[:message])

    render json: { message: response['response'] }
  end

  def inbox_assistant
    assistant = @conversation.inbox.captain_assistant

    if assistant
      render json: { assistant: { id: assistant.id, name: assistant.name } }
    else
      render json: { assistant: nil }
    end
  end

  def permitted_update_params
    super.merge(params.permit(:sla_policy_id))
  end

  private

  def copilot_params
    params.permit(:previous_messages, :message, :assistant_id)
  end
end
