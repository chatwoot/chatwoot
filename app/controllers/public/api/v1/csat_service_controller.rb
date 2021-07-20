class Public::Api::V1::CsatServiceController < PublicController
  before_action :set_conversation
  before_action :set_message

  def show; end

  def update
    @message.update!(message_update_params[:message])
  end

  private

  def set_conversation
    return if params[:id].blank?

    @conversation = Conversation.find_by!(uuid: params[:id])
  end

  def set_message
    @message = @conversation.messages.find_by!(content_type: 'input_csat')
  end

  def message_update_params
    params.permit(message: [{ submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }] }])
  end
end
