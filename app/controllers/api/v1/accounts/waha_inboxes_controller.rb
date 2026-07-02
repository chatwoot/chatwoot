class Api::V1::Accounts::WahaInboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox, only: [:connection, :reconnect]
  before_action :ensure_waha_inbox, only: [:connection, :reconnect]

  # Estados internos do motor mapeados para termos neutros (whitelabel).
  STATUS_MAP = {
    'WORKING' => 'connected',
    'SCAN_QR_CODE' => 'awaiting_scan',
    'STARTING' => 'connecting',
    'FAILED' => 'failed',
    'STOPPED' => 'disconnected'
  }.freeze

  def create
    authorize ::Inbox
    result = Waha::InboxProvisioner.new(
      account: Current.account,
      phone: permitted_create_params[:phone],
      api_access_token: current_user.access_token&.token,
      display_name: permitted_create_params[:name],
      ai_agent: permitted_create_params[:ai_agent]
    ).perform

    render json: { id: result.inbox.id, name: result.inbox.name }, status: :ok
  rescue Waha::InboxProvisioner::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Saúde + QR. Não retorna nenhum termo interno do motor.
  def connection
    session = waha_session
    client = Waha::Client.new
    remote = safe_session(client, session)
    status = STATUS_MAP.fetch(remote['status'], 'unknown')
    qr = status == 'connected' ? nil : safe_qr(client, session)

    render json: {
      status: status,
      connected: status == 'connected',
      phone: remote.dig('me', 'id').to_s.split('@').first.presence || session,
      qr: qr
    }
  end

  # Reinicia o pareamento (gera novo QR).
  def reconnect
    session = waha_session
    client = Waha::Client.new
    begin
      client.logout_session(session)
    rescue Waha::Client::Error
      client.restart_session(session)
    end
    render json: { status: 'connecting' }
  rescue Waha::Client::Error => e
    # Detalhe só nos logs; ao cliente, código estável (pode conter resposta do motor).
    Rails.logger.error("[Waha] reconnect failed for inbox #{@inbox.id}: #{e.message}")
    render json: { error: 'reconnect_failed' }, status: :unprocessable_entity
  end

  private

  # QR + reconectar são ações sensíveis (mutam/expoem pareamento): exigem admin.
  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
  end

  def ensure_waha_inbox
    return if @inbox.channel.is_a?(Channel::Api) && waha_attributes['provider'] == 'waha'

    render json: { error: 'not_a_waha_inbox' }, status: :unprocessable_entity
  end

  def waha_attributes
    (@inbox.channel.additional_attributes || {}).to_h
  end

  def waha_session
    waha_attributes['session']
  end

  def safe_session(client, session)
    client.get_session(session) || {}
  rescue Waha::Client::Error
    {}
  end

  def safe_qr(client, session)
    client.qr_value(session)['value']
  rescue StandardError
    nil
  end

  def permitted_create_params
    params.permit(:phone, :name, :ai_agent)
  end
end
