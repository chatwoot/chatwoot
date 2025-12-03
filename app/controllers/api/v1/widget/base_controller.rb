class Api::V1::Widget::BaseController < ApplicationController
  include SwitchLocale
  include WebsiteTokenHelper

  before_action :set_web_widget
  before_action :set_contact

  private

  def conversations
    if @contact_inbox.hmac_verified?
      verified_contact_inbox_ids = @contact.contact_inboxes.where(inbox_id: auth_token_params[:inbox_id], hmac_verified: true).map(&:id)
      @conversations = @contact.conversations.where(contact_inbox_id: verified_contact_inbox_ids)
    else
      @conversations = @contact_inbox.conversations.where(inbox_id: auth_token_params[:inbox_id])
    end
  end

  def conversation
    @conversation ||= conversations.last
  end

  def create_conversation
    ::Conversation.create!(conversation_params)
  end

  def inbox
    @inbox ||= ::Inbox.find_by(id: auth_token_params[:inbox_id])
  end

  # assign bitespeed bot to conversation
  def bot_user
    query = inbox.account.users.where('email LIKE ?', 'cx.%@bitespeed.co')
    Rails.logger.info "bot_user query: #{query.to_sql}"
    query.first
  end

  def conversation_params
    # FIXME: typo referrer in additional attributes, will probably require a migration.
    Rails.logger.info("BotUserFound, #{bot_user.inspect}")
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser_language: browser.accept_language&.first&.code,
        browser: browser_params,
        initiated_at: timestamp_params,
        referer: permitted_params[:message][:referer_url]
      },
      assignee_id: bot_user.id,
      custom_attributes: permitted_params[:custom_attributes].presence || {}
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
    Rails.logger.info("Permitted params: #{permitted_params}")
    permitted_params.dig(:contact, :phone_number)
  end

  def browser_params
    {
      browser_name: browser.name,
      browser_version: browser.full_version,
      device_name: browser.device.name,
      platform_name: browser.platform.name,
      platform_version: browser.platform.version
    }
  end

  def timestamp_params
    { timestamp: permitted_params[:message][:timestamp] }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def message_params
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: permitted_params[:message][:content],
      inbox_id: conversation.inbox_id,
      private: permitted_params[:message][:private] || false,
      content_attributes: {
        in_reply_to: permitted_params[:message][:reply_to],
        selected_reply: permitted_params[:message][:selected_reply],
        previous_selected_replies: permitted_params[:message][:previous_selected_replies],
        product_id_for_more_info: permitted_params[:message][:product_id_for_more_info],
        product_page: permitted_params[:message][:product_page],
        pre_chat_form_response: permitted_params[:message][:pre_chat_form_response],
        assign_to_agent: permitted_params[:message][:assign_to_agent],
        conversation_resolved: permitted_params[:message][:conversation_resolved],
        phone_number: permitted_params[:message][:phone_number],
        order_id: permitted_params[:message][:order_id],
        product_id: permitted_params[:message][:product_id]
      },
      echo_id: permitted_params[:message][:echo_id],
      message_type: :incoming
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
