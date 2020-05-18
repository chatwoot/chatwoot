class WidgetsController < ActionController::Base
  before_action :set_global_config
  before_action :set_web_widget
  before_action :set_decoded_token
  before_action :set_contact
  before_action :set_participant
  before_action :build_participant_token

  def index; end

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'INSTALLATION_NAME', 'WIDGET_BRAND_URL')
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_decoded_token
    @auth_token_params = find_token || {}
  end

  def find_token
    cw_share_link         = permitted_params[:chatwoot_share_link]
    cw_group_conversation = permitted_params[:cw_group_conversation]
    @share_link           = cw_group_conversation || cw_share_link
    cw_conversation       = permitted_params[:cw_conversation]
    @token                = @share_link || cw_conversation

    ::Widget::TokenService.new(token: @token).decode_token if @token.present?
  end

  def build_token
    payload = {
      source_id: @contact_inbox.source_id,
      inbox_id: @web_widget.inbox.id
    }

    @token = ::Widget::TokenService.new(payload: payload).generate_token
  end

  def set_participant_token
    # TODO
  end

  def build_participant_token
    return if @participant.blank?

    conversation_participant = ConversationParticipant.find_by(
      contact: @participant,
      conversation: @conversation
    )
    payload = {
      participant_uuid: conversation_participant.uuid
    }

    @participant_token = ::Widget::TokenService.new(payload: payload).generate_token
  end

  def set_contact
    @contact = find_contact || build_contact
  end

  def find_contact
    return if @auth_token_params.empty?

    @contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: @auth_token_params[:source_id]
    )

    @contact_inbox ? @contact_inbox.contact : nil
  end

  def build_contact
    @contact_inbox = @web_widget.create_contact_inbox

    build_token

    @contact_inbox.contact
  end

  def set_participant
    return if @share_link.blank?

    @participant = find_participant || build_participant
  end

  def find_participant
    return if @auth_token_params.empty?

    uuid = @auth_token_params[:participant_uuid]
    return if uuid.blank?

    conversation_participant = ConversationParticipant.find_by!(uuid: uuid)
    @participant = conversation_participant.contact
  end

  def build_participant
    @conversation = find_conversation
    conversation_participant = @web_widget.create_conversation_participant(@conversation)

    conversation_participant.contact
  end

  def find_conversation
    @contact_inbox.conversations.order(:created_at).last
  end

  def permitted_params
    params.permit(:website_token,
                  :cw_conversation,
                  :chatwoot_share_link,
                  :cw_group_conversation)
  end
end
