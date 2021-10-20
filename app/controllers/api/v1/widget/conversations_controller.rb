class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :set_conversation, except: [:index, :create]

  def index
    @conversations = conversations
  end

  def create
    ActiveRecord::Base.transaction do
      update_contact(contact_email) if @contact.email.blank? && contact_email.present?
      @conversation = create_conversation
      @conversation.messages.create(message_params)
    end
  end

  def show
  end

  def update_last_seen
    head :ok && return if @conversation.nil?

    @conversation.contact_last_seen_at = DateTime.now.utc
    @conversation.save!
    head :ok
  end

  def transcript
    if permitted_params[:email].present? && @conversation.present?
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(
        @conversation,
        permitted_params[:email]
      )&.deliver_later
    end
    head :ok
  end

  def toggle_typing
    head :ok && return if @conversation.nil?

    case permitted_params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  private

  def set_conversation
    @conversation = @conversations.find_by(display_id: params[:id])
  end

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: @contact)
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token, :email, contact: [:name, :email], message: [:content, :referer_url, :timestamp, :echo_id])
  end
end
