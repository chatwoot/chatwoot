module Enterprise::Api::V1::Accounts::ConversationsController
  extend ActiveSupport::Concern
  included do
    before_action :set_topic, only: [:copilot]
  end

  def copilot
    # First try to get the user's preferred topic from UI settings or from the request
    topic_id = copilot_params[:topic_id] || current_user.ui_settings&.dig('preferred_aiagent_topic_id')

    # Find the topic either by ID or from inbox
    topic = if topic_id.present?
              Aiagent::Topic.find_by(id: topic_id, account_id: Current.account.id)
            else
              @conversation.inbox.aiagent_topic
            end

    return render json: { message: I18n.t('aiagent.copilot_error') } unless topic

    response = Aiagent::Copilot::ChatService.new(
      topic,
      previous_messages: copilot_params[:previous_messages],
      conversation_history: @conversation.to_llm_text,
      language: @conversation.account.locale_english_name
    ).generate_response(copilot_params[:message])

    render json: { message: response['response'] }
  end

  def inbox_topic
    topic = @conversation.inbox.aiagent_topic

    if topic
      render json: { topic: { id: topic.id, name: topic.name } }
    else
      render json: { topic: nil }
    end
  end

  def permitted_update_params
    super.merge(params.permit(:sla_policy_id))
  end

  private

  def copilot_params
    params.permit(:previous_messages, :message, :topic_id)
  end
end
