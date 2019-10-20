class Api::V1::Widget::MessagesController < ApplicationController
  # TODO: move widget apis to different controller.
  skip_before_action :set_current_user, only: [:create_incoming]
  skip_before_action :check_subscription, only: [:create_incoming]
  skip_around_action :handle_with_exception, only: [:create_incoming]

  def create_incoming
    builder = Integrations::Widget::IncomingMessageBuilder.new(incoming_message_params)
    builder.perform
    render json: builder.message
  end

  def create_outgoing
    builder = Integrations::Widget::OutgoingMessageBuilder.new(outgoing_message_params)
    builder.perform
    render json: builder.message
  end

  private

  def incoming_message_params
    params.require(:message).permit(:contact_id, :inbox_id, :content)
  end

  def outgoing_message_params
    params.require(:message).permit(:user_id, :inbox_id, :content, :conversation_id)
  end
end
