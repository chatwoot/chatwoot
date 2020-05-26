class Api::V1::Widget::BaseController < ApplicationController
  private

  def conversation
    @conversation ||= @contact_inbox.conversations.where(
      inbox_id: decoded_auth_token[:inbox_id]
    ).last
  end

  def decoded_auth_token
    @decoded_auth_token ||= ::Widget::TokenService.new(token: request.headers[header_name]).decode_token
  end

  def header_name
    'X-Auth-Token'
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @account = @web_widget.account
    switch_locale @account
  end

  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: decoded_auth_token[:source_id]
    )
    @contact = set_participant || @contact_inbox.contact
  end

  def set_participant
    uuid = ::Widget::TokenService.new(token: request.headers['X-Participant-Token']).decode_token[:participant_uuid]
    return if uuid.blank?

    conversation_participant = ConversationParticipant.find_by!(uuid: uuid)
    @participant = conversation_participant.contact
  end
end
