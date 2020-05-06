class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :set_web_widget
  before_action :set_contact

  def toggle_typing
    head :ok && return if conversation.nil?

    if permitted_params[:typing_status] == 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    elsif permitted_params[:typing_status] == 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  private

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token)
  end
end
