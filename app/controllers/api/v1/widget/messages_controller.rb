class Api::V1::Widget::MessagesController < ActionController::Base
  before_action :set_conversation, only: [:create]

  def index
    @messages = conversation.nil? ? [] : message_finder.perform
  end

  def create
    @message = conversation.messages.new(message_params)
    @message.save!
  end

  private

  def conversation
    @conversation ||= ::Conversation.find_by(
      contact_id: cookie_params[:contact_id],
      inbox_id: cookie_params[:inbox_id]
    )
  end

  def set_conversation
    @conversation = ::Conversation.create!(conversation_params) if conversation.nil?
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      content: permitted_params[:message][:content]
    }
  end

  def conversation_params
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: cookie_params[:contact_id],
      additional_attributes: {
        browser: browser_params
      }
    }
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

  def inbox
    @inbox ||= ::Inbox.find_by(id: cookie_params[:inbox_id])
  end

  def cookie_params
    @cookie_params ||= JWT.decode(
      request.headers[header_name], secret_key, true, algorithm: 'HS256'
    ).first.symbolize_keys
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: permitted_params[:before]
    }
  end

  def message_finder
    @message_finder ||= MessageFinder.new(conversation, message_finder_params)
  end

  def header_name
    'X-Auth-Token'
  end

  def permitted_params
    params.permit(:before, message: [:content])
  end

  def secret_key
    Rails.application.secrets.secret_key_base
  end
end
