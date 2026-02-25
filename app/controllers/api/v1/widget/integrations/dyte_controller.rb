class Api::V1::Widget::Integrations::DyteController < Api::V1::Widget::BaseController
  before_action :set_message

  def add_participant_to_meeting
    if @message.content_type != 'integrations'
      return render json: {
        error: I18n.t('errors.dyte.invalid_message_type')
      }, status: :unprocessable_entity
    end

    response = dyte_processor_service.add_participant_to_meeting(
      @message.content_attributes['data']['meeting_id'],
      @conversation.contact
    )
    render_response(response)
  end

  private

  def render_response(response)
    render json: response, status: response[:error].blank? ? :ok : :unprocessable_entity
  end

  def dyte_processor_service
    Integrations::Dyte::ProcessorService.new(account: @web_widget.inbox.account, conversation: @conversation)
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:message_id])
    @conversation = @message.conversation
  end

  def permitted_params
    params.permit(:website_token, :message_id)
  end
end
