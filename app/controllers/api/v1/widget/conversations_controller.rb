class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types

  def index
    @conversation = conversation
  end

  def create
    ActiveRecord::Base.transaction do
      process_update_contact
      @conversation = create_conversation
      conversation.messages.create!(message_params)
    end
  end

  def process_update_contact
    @contact = ContactIdentifyAction.new(
      contact: @contact,
      params: { email: contact_email, phone_number: contact_phone_number, name: contact_name },
      retain_original_contact_name: true,
      discard_invalid_attrs: true
    ).perform
  end

  def update_last_seen
    head :ok && return if conversation.nil?

    conversation.contact_last_seen_at = DateTime.now.utc
    conversation.save!
    head :ok
  end

  def transcript
    if permitted_params[:email].present? && conversation.present?
      ConversationReplyMailer.with(account: conversation.account).conversation_transcript(
        conversation,
        permitted_params[:email]
      )&.deliver_later
    end
    head :ok
  end

  def toggle_typing
    head :ok && return if conversation.nil?

    case permitted_params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  def toggle_status
    return head :not_found if conversation.nil?

    return head :forbidden unless @web_widget.end_conversation?

    unless conversation.resolved?
      conversation.status = :resolved
      conversation.save!
    end
    head :ok
  end

  private

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token, :email, contact: [:name, :email, :phone_number],
                                                               message: [:content, :referer_url, :timestamp, :echo_id],
                                                               custom_attributes: {})
  end
end
