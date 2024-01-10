class Public::Api::V1::Inboxes::ConversationsController < Public::Api::V1::InboxesController
  include Events::Types
  before_action :set_conversation, only: [:toggle_typing, :update_last_seen]

  def index
    @conversations = @contact_inbox.hmac_verified? ? @contact.conversations : @contact_inbox.conversations
  end

  def create
    @conversation = create_conversation
  end

  def toggle_typing
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end
    head :ok
  end

  def update_last_seen
    @conversation.contact_last_seen_at = DateTime.now.utc
    @conversation.save!
    ::Conversations::UpdateMessageStatusJob.perform_later(@conversation.id, @conversation.contact_last_seen_at)
    head :ok
  end

  private

  def set_conversation
    @conversation = @contact_inbox.contact.conversations.find_by!(display_id: params[:id])
  end

  def create_conversation
    ConversationBuilder.new(params: conversation_params, contact_inbox: @contact_inbox).perform
  end

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: @conversation.contact)
  end

  def conversation_params
    params.permit(custom_attributes: {})
  end
end
