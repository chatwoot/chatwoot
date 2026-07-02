class Api::V1::Accounts::Autonomia::InviteConnectionsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox, only: [:connection, :reconnect]

  STATUS_MAP = {
    'WORKING' => 'connected',
    'SCAN_QR_CODE' => 'awaiting_scan',
    'STARTING' => 'connecting',
    'FAILED' => 'failed',
    'STOPPED' => 'disconnected'
  }.freeze

  def show
    inbox = invite_connection_inbox(include_connected: true)
    return render json: { inbox: nil } if inbox.blank?

    render json: {
      inbox: inbox_payload(inbox),
      connected: invite_connection_status(inbox) == 'connected'
    }
  end

  def connection
    session = waha_session(@inbox)
    client = Waha::Client.new
    remote = safe_session(client, session)
    status = STATUS_MAP.fetch(remote['status'], 'unknown')
    mark_connected!(@inbox) if status == 'connected'

    render json: {
      status: status,
      connected: status == 'connected',
      phone: remote.dig('me', 'id').to_s.split('@').first.presence || session,
      qr: status == 'connected' ? nil : safe_qr(client, session),
      inbox: inbox_payload(@inbox)
    }
  end

  def reconnect
    session = waha_session(@inbox)
    client = Waha::Client.new
    begin
      client.logout_session(session)
    rescue Waha::Client::Error
      client.restart_session(session)
    end
    render json: { status: 'connecting' }
  rescue Waha::Client::Error => e
    Rails.logger.error("[Waha] invited reconnect failed for inbox #{@inbox.id}: #{e.message}")
    render json: { error: 'reconnect_failed' }, status: :unprocessable_entity
  end

  private

  def fetch_inbox
    @inbox = invite_connection_inbox(inbox_id: params[:inbox_id])
    render json: { error: 'not_found' }, status: :not_found if @inbox.blank?
  end

  def invite_connection_inbox(inbox_id: nil, include_connected: false)
    Current.account.inboxes.where(channel_type: 'Channel::Api').includes(:channel).find do |inbox|
      next false if inbox_id.present? && inbox.id != inbox_id.to_i

      connection = invite_connection_attributes(inbox)
      next false if connection['user_id'].to_i != Current.user.id
      next false if !include_connected && connection['status'] == 'connected'

      waha_inbox?(inbox)
    end
  end

  def invite_connection_attributes(inbox)
    attrs = (inbox.channel.additional_attributes || {}).to_h
    attrs['autonomia_invite_connection'] || {}
  end

  def waha_inbox?(inbox)
    attrs = (inbox.channel.additional_attributes || {}).to_h
    attrs['provider'] == 'waha'
  end

  def waha_session(inbox)
    (inbox.channel.additional_attributes || {}).to_h['session']
  end

  def invite_connection_status(inbox)
    invite_connection_attributes(inbox)['status']
  end

  def mark_connected!(inbox)
    channel = inbox.channel
    attrs = (channel.additional_attributes || {}).to_h
    connection = (attrs['autonomia_invite_connection'] || {}).merge(
      'status' => 'connected',
      'connected_at' => Time.current.iso8601
    )
    channel.update!(additional_attributes: attrs.merge('autonomia_invite_connection' => connection))
  end

  def inbox_payload(inbox)
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type
    }
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
end
