class Api::V1::Widget::BaseController < ApplicationController
  include SwitchLocale

  before_action :set_web_widget
  before_action :set_contact
  around_action :switch_locale_using_account_locale

  private

  def conversations
    @conversations = @contact_inbox.conversations.where(inbox_id: auth_token_params[:inbox_id])
  end

  def conversation
    @conversation ||= conversations.last
  end

  def auth_token_params
    @auth_token_params ||= ::Widget::TokenService.new(token: request.headers[header_name]).decode_token
  end

  def header_name
    'X-Auth-Token'
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @current_account = @web_widget.account
  end

  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: auth_token_params[:source_id]
    )
    @contact = @contact_inbox.contact
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
end
