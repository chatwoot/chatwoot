class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :render_not_found_if_empty, only: [:toggle_typing, :toggle_status, :set_custom_attributes, :destroy_custom_attributes]

  def index
    @conversation = conversation
  end

  def create
    ActiveRecord::Base.transaction do
      process_update_contact
      @conversation = create_conversation
      conversation.messages.create!(message_params)
      # TODO: Temporary fix for message type cast issue, since message_type is returning as string instead of integer
      conversation.reload
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
    ::Conversations::UpdateMessageStatusJob.perform_later(conversation.id, conversation.contact_last_seen_at)
    head :ok
  end

  def transcript
    if conversation.present? && conversation.contact.present? && conversation.contact.email.present?
      ConversationReplyMailer.with(account: conversation.account).conversation_transcript(
        conversation,
        conversation.contact.email
      )&.deliver_later
    end
    head :ok
  end

  def toggle_typing
    case permitted_params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  def toggle_status
    return head :forbidden unless @web_widget.end_conversation?

    unless conversation.resolved?
      conversation.status = :resolved
      conversation.save!
    end
    head :ok
  end

  def set_custom_attributes
    conversation.update!(custom_attributes: permitted_params[:custom_attributes])
  end

  def destroy_custom_attributes
    conversation.custom_attributes = conversation.custom_attributes.excluding(params[:custom_attribute])
    conversation.save!
    render json: conversation
  end

  private

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
  end

  def render_not_found_if_empty
    return head :not_found if conversation.nil?
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token, :email, contact: [:name, :email, :phone_number],
                                                               message: [:content, :referer_url, :timestamp, :echo_id],
                                                               custom_attributes: {})
  end
end
