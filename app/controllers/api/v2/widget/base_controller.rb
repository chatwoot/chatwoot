class Api::V2::Widget::BaseController < ApplicationController
  include SwitchLocale
  include WebsiteTokenHelper

  before_action :set_web_widget
  before_action :validate_token_inbox
  before_action :set_contact

  private

  # The widget JWT carries an inbox_id, but v1 never asserted it belongs to the
  # inbox resolved from website_token. Reject mismatched tokens outright.
  def validate_token_inbox
    return if auth_token_params[:inbox_id].blank?
    return if auth_token_params[:inbox_id].to_i == inbox.id

    render json: { error: 'Invalid auth token' }, status: :unauthorized
  end

  def inbox
    @web_widget.inbox
  end

  # Overridden in enterprise: true when the inbox has a Captain assistant with credits
  def ai_agent_active?
    false
  end

  def conversations
    @conversations ||= if @contact_inbox.hmac_verified?
                         verified_contact_inbox_ids = @contact.contact_inboxes.where(inbox_id: inbox.id, hmac_verified: true).select(:id)
                         @contact.conversations.where(contact_inbox_id: verified_contact_inbox_ids)
                       else
                         @contact_inbox.conversations.where(inbox_id: inbox.id)
                       end
  end

  def conversation
    @conversation ||= conversations.find_by!(display_id: params[:conversation_display_id] || params[:display_id])
  end

  # Human-section conversations must stay out of the AI's hands. Conversation
  # callbacks force `pending` whenever a bot is active, and resolved
  # conversations re-enter `pending` on new incoming messages; flip them back
  # to open. Captain's ResponseBuilderJob re-checks `pending?` before replying,
  # so this also cancels any job enqueued in between.
  def ensure_human_section_status(conversation)
    return unless ai_agent_active?
    return unless conversation.additional_attributes['widget_section'] == 'human'
    return unless conversation.reload.pending?

    conversation.update!(status: :open, assignee_agent_bot_id: nil)
  end

  def message_params_for(conversation)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      sender: @contact,
      content: permitted_params[:message][:content],
      content_attributes: {
        in_reply_to: permitted_params[:message][:reply_to]
      },
      echo_id: permitted_params[:message][:echo_id],
      message_type: :incoming
    }
  end

  def contact_email
    permitted_params.dig(:contact, :email)&.downcase
  end

  def contact_name
    return if @contact.email.present? || @contact.phone_number.present? || @contact.identifier.present?

    permitted_params.dig(:contact, :name) || (contact_email.split('@')[0] if contact_email.present?)
  end

  def contact_phone_number
    permitted_params.dig(:contact, :phone_number)
  end

  def contact_custom_attributes
    permitted_params.dig(:contact, :custom_attributes)&.to_h
  end
end

Api::V2::Widget::BaseController.prepend_mod_with('Api::V2::Widget::BaseController')
