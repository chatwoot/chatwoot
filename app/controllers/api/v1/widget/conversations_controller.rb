class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types

  def index
    @conversation = conversation
  end

  def update_last_seen
    head :ok && return if conversation.nil?

    conversation.user_last_seen_at = DateTime.now.utc
    conversation.save!
    head :ok
  end

  def transcript
    if permitted_params[:email].present? && conversation.present?
      ConversationReplyMailer.conversation_transcript(
        conversation,
        permitted_params[:email]
      )&.deliver_later
    end
    head :ok
  end

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
    params.permit(:id, :typing_status, :website_token, :email)
  end
end
