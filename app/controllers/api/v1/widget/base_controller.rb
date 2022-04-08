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

  def conversation_params
    # FIXME: typo referrer in additional attributes, will probably require a migration.
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser: browser_params,
        referer: permitted_params[:message][:referer_url],
        initiated_at: timestamp_params
      },
      custom_attributes: permitted_params[:custom_attributes].presence || {}
    }
  end

  def update_contact(email)
    contact_with_email = @current_account.contacts.find_by(email: email)
    if contact_with_email
      @contact = ::ContactMergeAction.new(
        account: @current_account,
        base_contact: contact_with_email,
        mergee_contact: @contact
      ).perform
    else
      @contact.update!(email: email)
    end
  end

  def update_contact_phone_number(phone_number)
    contact_with_phone_number = @current_account.contacts.find_by(phone_number: phone_number)
    if contact_with_phone_number
      @contact = ::ContactMergeAction.new(
        account: @current_account,
        base_contact: contact_with_phone_number,
        mergee_contact: @contact
      ).perform
    else
      @contact.update!(phone_number: phone_number)
    end
  end

  def contact_email
    permitted_params[:contact][:email].downcase if permitted_params[:contact].present?
  end

  def contact_name
    params[:contact][:name] || contact_email.split('@')[0] if contact_email.present?
  end

  def contact_phone_number
    params[:contact][:phone_number]
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

  def message_params
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: permitted_params[:message][:content],
      inbox_id: conversation.inbox_id,
      echo_id: permitted_params[:message][:echo_id],
      message_type: :incoming
    }
  end
end
