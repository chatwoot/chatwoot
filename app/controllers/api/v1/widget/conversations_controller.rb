class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types

  def index
    @conversations = conversations
  end

  def create
    if valid_message_params?
      @conversation = ::Conversation.create!(conversation_params)
      build_message
    else
      render_could_not_create_error(
        I18n.t('errors.widget.conversation.invalid_message_params')
      )
    end
  end

  def update_last_seen
    head :ok && return if conversation.nil?

    conversation.contact_last_seen_at = DateTime.now.utc
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

    case permitted_params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  private

  def valid_message_params?
    message_params = permitted_params[:message]

    message_params.present? && (message_params[:content].present? || message_params[:attachments].present?)
  end

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
  end

  def conversation_params
    {
      account_id: @web_widget.inbox.account_id,
      inbox_id: @web_widget.inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser: browser_params,
        referer: permitted_params[:message][:referer_url],
        initiated_at: {
          timestamp: permitted_params[:message][:timestamp]
        }
      }
    }
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token, :email, message: [:content, :echo_id, { attachments: [] }])
  end

  def conversation
    @conversation ||= conversations.find_by(display_id: permitted_params[:id])
  end
end
