class Api::V2::Widget::ConversationsController < Api::V2::Widget::BaseController
  include Events::Types

  RESULTS_PER_PAGE = 25
  SECTIONS = %w[human ai].freeze

  def index
    # Conversations created before v2 carry no section tag; they belong in the human list.
    scoped = if section == 'ai'
               conversations.where("additional_attributes ->> 'widget_section' = 'ai'")
             else
               conversations.where("COALESCE(additional_attributes ->> 'widget_section', 'human') <> 'ai'")
             end
    @conversations_page = scoped.includes(:assignee, :inbox).order(last_activity_at: :desc).page(permitted_params[:page]).per(RESULTS_PER_PAGE)
    @unread_counts = unread_counts_for(@conversations_page)
  end

  def show
    @conversation = conversation
  end

  def create
    return render_ai_unavailable if section == 'ai' && !ai_agent_active?

    ActiveRecord::Base.transaction do
      process_update_contact
      @conversation = build_conversation
      @conversation.messages.create!(message_params_for(@conversation))
    end
    ensure_human_section_status(@conversation)
    @conversation.reload
  end

  def resolve
    return head :forbidden unless @web_widget.end_conversation?

    conversation.resolved! unless conversation.resolved?
    head :ok
  end

  def update_last_seen
    conversation.contact_last_seen_at = DateTime.now.utc
    conversation.save!
    ::Conversations::UpdateMessageStatusJob.perform_later(conversation.id, conversation.contact_last_seen_at)
    head :ok
  end

  def toggle_typing
    event = permitted_params[:typing_status] == 'on' ? CONVERSATION_TYPING_ON : CONVERSATION_TYPING_OFF
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
    head :ok
  end

  private

  def section
    SECTIONS.include?(permitted_params[:section]) ? permitted_params[:section] : 'human'
  end

  def render_ai_unavailable
    render json: { error: 'AI assistant is not available for this inbox' }, status: :not_found
  end

  def process_update_contact
    @contact = ContactIdentifyAction.new(
      contact: @contact,
      params: { email: contact_email, phone_number: contact_phone_number, name: contact_name, custom_attributes: contact_custom_attributes },
      retain_original_contact_name: true,
      discard_invalid_attrs: true
    ).perform
  end

  def build_conversation
    ConversationBuilder.new(
      params: ActionController::Parameters.new(
        additional_attributes: conversation_additional_attributes,
        custom_attributes: permitted_params[:custom_attributes].presence || {}
      ),
      contact_inbox: @contact_inbox
    ).perform
  end

  def conversation_additional_attributes
    {
      widget_section: section,
      browser_language: browser.accept_language&.first&.code,
      browser: {
        browser_name: browser.name,
        browser_version: browser.full_version,
        device_name: browser.device.name,
        platform_name: browser.platform.name,
        platform_version: browser.platform.version
      },
      initiated_at: { timestamp: permitted_params[:message][:timestamp] },
      referer: permitted_params[:message][:referer_url]
    }
  end

  def unread_counts_for(conversations)
    Message.where(conversation_id: conversations.map(&:id), private: false)
           .where(message_type: [:outgoing, :template])
           .joins(:conversation)
           .where('messages.created_at > COALESCE(conversations.contact_last_seen_at, to_timestamp(0))')
           .reorder(nil)
           .group(:conversation_id)
           .count
  end

  def permitted_params
    params.permit(:website_token, :display_id, :page, :section, :typing_status,
                  contact: [:name, :email, :phone_number, { custom_attributes: {} }],
                  message: [:content, :referer_url, :timestamp, :echo_id, :reply_to],
                  custom_attributes: {})
  end
end
