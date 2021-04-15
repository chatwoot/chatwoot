class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  include Events::Types

  before_action :conversation, except: [:index]
  before_action :contact_inbox, only: [:create]

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def meta
    result = conversation_finder.perform
    @conversations_count = result[:count]
  end

  def search
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def create
    ActiveRecord::Base.transaction do
      @conversation = ::Conversation.create!(conversation_params)
      Messages::MessageBuilder.new(Current.user, @conversation, params[:message]).perform if params[:message].present?
    end
  end

  def show; end

  def mute
    @conversation.mute!
    head :ok
  end

  def unmute
    @conversation.unmute!
    head :ok
  end

  def transcript
    ConversationReplyMailer.conversation_transcript(@conversation, params[:email])&.deliver_later if params[:email].present?
    head :ok
  end

  def toggle_status
    if params[:status]
      @conversation.status = params[:status]
      @status = @conversation.save
    else
      @status = @conversation.toggle_status
    end
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end
    head :ok
  end

  def update_last_seen
    @conversation.agent_last_seen_at = DateTime.now.utc
    @conversation.save!
  end

  private

  def trigger_typing_event(event)
    user = current_user.presence || @resource
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user)
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by(display_id: params[:id])
  end

  def contact_inbox
    @contact_inbox = build_contact_inbox

    @contact_inbox ||= ::ContactInbox.find_by!(source_id: params[:source_id])
  end

  def build_contact_inbox
    return if params[:contact_id].blank? || params[:inbox_id].blank?

    ContactInboxBuilder.new(
      contact_id: params[:contact_id],
      inbox_id: params[:inbox_id],
      source_id: params[:source_id]
    ).perform
  end

  def conversation_params
    additional_attributes = params[:additional_attributes]&.permit! || {}
    {
      account_id: Current.account.id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes
    }
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(current_user, params)
  end
end
