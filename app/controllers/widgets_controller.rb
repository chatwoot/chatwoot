class WidgetsController < ActionController::Base
  before_action :set_global_config
  before_action :set_web_widget
  before_action :set_decoded_auth_token
  before_action :set_contact
  before_action :set_share_link
  before_action :set_decoded_participant_token

  def index; end

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'INSTALLATION_NAME', 'WIDGET_BRAND_URL')
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_decoded_auth_token
    @decoded_auth_token = find_token || {}
  end

  def find_token
    cw_share_link         = permitted_params[:chatwoot_share_link]
    cw_conversation       = permitted_params[:cw_conversation]
    @token                = cw_share_link || cw_conversation

    decode_token(@token) if @token.present?
  end

  def build_token(payload = nil)
    payload ||= {
      source_id: @contact_inbox.source_id,
      inbox_id: @web_widget.inbox.id
    }

    ::Widget::TokenService.new(payload: payload).generate_token
  end

  def decode_token(token)
    ::Widget::TokenService.new(token: token).decode_token
  end

  def set_share_link
    share_link = permitted_params[:cw_group_conversation] || permitted_params[:chatwoot_share_link]

    @share_link = share_link.present?
  end

  def set_decoded_participant_token
    return unless @share_link

    @participant_token = permitted_params[:cw_group_conversation]
    if @participant_token
      @decoded_participant_token = decode_token(@participant_token)
    else
      build_participant
      build_participant_token
    end
  end

  def build_participant_token
    participant_token = @decoded_auth_token.clone
    participant_token[:participant_uuid] = @conversation_participant.uuid
    @participant_token = build_token(participant_token)
  end

  def set_contact
    @contact = find_contact || build_contact
  end

  def find_contact
    return if @decoded_auth_token.empty?

    @contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: @decoded_auth_token[:source_id]
    )

    @contact_inbox ? @contact_inbox.contact : nil
  end

  def build_contact
    @contact_inbox = @web_widget.create_contact_inbox

    @token = build_token

    @contact_inbox.contact
  end

  def build_participant
    conversation = find_conversation
    @conversation_participant = @web_widget.create_conversation_participant(conversation)
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
