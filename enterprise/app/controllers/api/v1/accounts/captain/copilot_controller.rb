class Api::V1::Accounts::Captain::CopilotController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:create]

  def create
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

  private

  def copilot_params
    params.permit(:message, :assistant_id, previous_messages: [])
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find(params[:conversation_id])
  end
end
