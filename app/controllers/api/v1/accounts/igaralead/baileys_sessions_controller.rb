class Api::V1::Accounts::Igaralead::BaileysSessionsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :check_authorization

  def qr_code
    channel = @inbox.channel
    return render json: { error: 'Not a Baileys channel' }, status: :unprocessable_entity unless channel.is_a?(Channel::BaileysWhatsapp)

    result = channel.request_qr_code
    if result.is_a?(Hash) && result['qr'].present?
      render json: { qr_code: result['qr'], session_id: channel.session_id, session_status: channel.session_status }
    else
      render json: { session_id: channel.session_id, session_status: channel.session_status, message: 'QR code requested, waiting for sidecar response' }
    end
  end

  def status
    channel = @inbox.channel
    return render json: { error: 'Not a Baileys channel' }, status: :unprocessable_entity unless channel.is_a?(Channel::BaileysWhatsapp)

    render json: {
      session_id: channel.session_id,
      session_status: channel.session_status,
      phone_number: channel.phone_number,
      last_connected_at: channel.last_connected_at,
      qr_code: channel.provider_config&.dig('qr_code')
    }
  end

  def disconnect
    channel = @inbox.channel
    return render json: { error: 'Not a Baileys channel' }, status: :unprocessable_entity unless channel.is_a?(Channel::BaileysWhatsapp)

    channel.disconnect_session
    render json: { status: 'disconnected' }
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
  end

  def check_authorization
    authorize @inbox, :update?
  end
end
