class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :validate_history_cursor, only: [:history]
  before_action :render_not_found_if_empty, only: [:toggle_typing, :toggle_status, :set_custom_attributes, :destroy_custom_attributes]

  RESULTS_PER_PAGE = 25
  def history
    @unread_count = Message.where(conversation_id: conversations.select(:id), message_type: :outgoing, private: false)
                           .joins(:conversation)
                           .where('messages.created_at > COALESCE(conversations.contact_last_seen_at, ?)', Time.zone.at(0)).count
    @history = conversations.order(created_at: :desc).limit(30)
    @history = @history.where('conversations.id < ?', params[:before]) if params[:before].present?
  end

  def index
    @conversation = conversation
  end

  def list
    @unread_conversation_count = unread_messages_for(conversations.select(:id)).distinct.count(:conversation_id)
    @conversations = conversations.includes(:assignee).order(last_activity_at: :desc).page(permitted_params[:page]).per(RESULTS_PER_PAGE)
    @unread_counts = unread_messages_for(@conversations.map(&:id)).group(:conversation_id).count
    @last_messages = last_messages_for(@conversations)
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
      params: { email: contact_email, phone_number: contact_phone_number, name: contact_name, custom_attributes: contact_custom_attributes },
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
    return head :too_many_requests if conversation.blank?
    return head :payment_required unless conversation.account.email_transcript_enabled?
    return head :too_many_requests unless conversation.account.within_email_rate_limit?

    send_transcript_email
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
    return head :forbidden unless @web_widget.inbox.api? || @web_widget.end_conversation?

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

  def validate_history_cursor
    return unless params.key?(:before)
    return if params[:before].is_a?(String) && params[:before].match?(/\A[1-9]\d*\z/)

    render json: { error: 'Invalid conversation cursor' }, status: :unprocessable_entity
  end

  def send_transcript_email
    return if conversation.contact&.email.blank?

    ConversationReplyMailer.with(account: conversation.account).conversation_transcript(
      conversation,
      conversation.contact.email
    )&.deliver_later
    conversation.account.increment_email_sent_count
  end

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
  end

  def unread_messages_for(conversation_ids)
    Message.joins(:conversation)
           .where(conversation_id: conversation_ids)
           .outgoing
           .where(private: false)
           .not_deleted
           .where('messages.created_at > COALESCE(conversations.contact_last_seen_at, to_timestamp(0))')
           .reorder(nil)
  end

  def last_messages_for(conversations)
    Message.where(conversation_id: conversations.map(&:id))
           .chat
           .not_deleted
           .select('DISTINCT ON (conversation_id) messages.*')
           .reorder(:conversation_id, created_at: :desc, id: :desc)
           .includes(:attachments, :sender)
           .index_by(&:conversation_id)
  end

  def render_not_found_if_empty
    return head :not_found if conversation.nil?
  end

  def permitted_params
    params.permit(:id, :page, :typing_status, :website_token, :email, contact: [:name, :email, :phone_number, { custom_attributes: {} }],
                                                                      message: [:content, :referer_url, :timestamp, :echo_id],
                                                                      custom_attributes: {})
  end
end
