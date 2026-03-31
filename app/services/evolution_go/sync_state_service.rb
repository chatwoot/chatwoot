class EvolutionGo::SyncStateService
  include EvolutionGo::PayloadHelper

  pattr_initialize [:channel!, { payload: nil }]

  def perform
    state = payload.present? ? state_from_payload : state_from_api
    persist_state(state)
    state
  rescue EvolutionGo::Client::Error, EvolutionGo::Client::ConfigurationError => e
    Rails.logger.error "[EVOLUTION_GO] State sync failed for channel #{channel.id}: #{e.message}"
    fallback_state
  end

  private

  def state_from_api
    instance = client.find_instance_by_name
    return fallback_state.merge('connection_status' => 'not_created') if instance.blank?

    status_payload = safe_fetch { client.fetch_status } || {}
    qr_payload = fetch_qr_payload(status_payload)
    build_state(api_state_attributes(instance, status_payload, qr_payload))
  end

  def state_from_payload
    event_name = normalized_event
    data = payload[:data].to_h.with_indifferent_access
    jid = data[:jid].presence || current_provider_config['jid']
    qr_image = qr_image_from(data)
    pairing_code = pairing_code_from(data)

    build_state(
      instance_id: payload[:instanceId].presence || current_provider_config['instance_id'],
      connected: connected_from_event(event_name),
      logged_in: logged_in_from_event(event_name, jid),
      jid: jid,
      qr_image: qr_image,
      pairing_code: pairing_code,
      connection_status: connection_status_for_event(event_name, qr_image)
    )
  end

  def build_state(state_attributes)
    phone_number = format_phone_number(state_attributes[:jid])

    {
      'instance_id' => state_attributes[:instance_id],
      'instance_name' => current_provider_config['instance_name'],
      'connected' => state_attributes[:connected],
      'logged_in' => state_attributes[:logged_in],
      'jid' => state_attributes[:jid],
      'phone_number' => phone_number,
      'qr_code' => state_attributes[:qr_image],
      'pairing_code' => state_attributes[:pairing_code],
      'connection_status' => state_attributes[:connection_status],
      'callback_webhook_url' => channel.inbox.callback_webhook_url,
      'reauthorization_required' => channel.reauthorization_required?
    }
  end

  def persist_state(state)
    provider_config = current_provider_config.merge(
      'instance_id' => state['instance_id'],
      'instance_name' => state['instance_name'],
      'jid' => state['jid'],
      'connected' => state['connected'],
      'logged_in' => state['logged_in'],
      'qr_code' => state['qr_code'],
      'pairing_code' => state['pairing_code'],
      'connection_status' => state['connection_status']
    ).compact

    attributes = {
      provider_config: provider_config,
      updated_at: Time.current
    }
    attributes[:phone_number] = state['phone_number'] if state['phone_number'].present?

    # rubocop:disable Rails/SkipsModelValidations
    # Persist webhook/API state without triggering provisioning callbacks again.
    channel.update_columns(attributes)
    # rubocop:enable Rails/SkipsModelValidations
    channel.provider_config = provider_config
    channel.phone_number = state['phone_number'] if state['phone_number'].present?
  end

  def fallback_state
    {
      'instance_id' => current_provider_config['instance_id'],
      'instance_name' => current_provider_config['instance_name'],
      'connected' => current_provider_config['connected'] || false,
      'logged_in' => current_provider_config['logged_in'] || false,
      'jid' => current_provider_config['jid'],
      'phone_number' => channel.phone_number,
      'qr_code' => current_provider_config['qr_code'],
      'pairing_code' => current_provider_config['pairing_code'],
      'connection_status' => current_provider_config['connection_status'] || 'disconnected',
      'callback_webhook_url' => channel.inbox.callback_webhook_url,
      'reauthorization_required' => channel.reauthorization_required?
    }
  end

  def fetch_qr_payload(status_payload)
    needs_qr = !payload_value(status_payload, :connected, :Connected, default: false) ||
               !payload_value(status_payload, :loggedIn, :LoggedIn, default: false)
    return {} unless needs_qr

    safe_fetch { client.fetch_qr_code } || {}
  end

  def connection_status_from(connected:, logged_in:, jid:, qr_image:, fallback:)
    return 'connected' if connected && (logged_in || format_phone_number(jid).present?)
    return 'awaiting_qr' if qr_image.present?
    return 'pairing' if connected

    fallback
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def connection_status_for_event(event_name, qr_image)
    case event_name
    when 'connected', 'pairsuccess'
      'connected'
    when 'qrcode', 'qrsuccess'
      qr_image.present? ? 'awaiting_qr' : 'pairing'
    when 'disconnected'
      qr_image.present? ? 'awaiting_qr' : 'disconnected'
    when 'qrtimeout'
      'qr_timeout'
    when 'loggedout'
      'logged_out'
    when 'temporaryban'
      'temporarily_banned'
    when 'connectfailure'
      'connect_failure'
    else
      'disconnected'
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def connected_from_event(event_name)
    %w[connected pairsuccess qrcode qrsuccess].include?(event_name)
  end

  def logged_in_from_event(event_name, jid)
    return true if %w[connected pairsuccess].include?(event_name)
    return false if %w[qrcode qrsuccess qrtimeout disconnected loggedout temporaryban connectfailure].include?(event_name)
    return true if jid.present?

    false
  end

  def normalized_event
    payload[:event].to_s.downcase
  end

  def api_state_attributes(instance, status_payload, qr_payload)
    connected = payload_value(status_payload, :connected, :Connected, default: instance['connected'])
    logged_in = payload_value(status_payload, :loggedIn, :LoggedIn)
    jid = payload_value(status_payload, :myJid, :MyJid, :jid, :Jid).presence || instance['jid']
    qr_image = qr_image_from(qr_payload)

    {
      instance_id: instance['id'],
      connected: connected,
      logged_in: logged_in,
      jid: jid,
      qr_image: qr_image,
      pairing_code: pairing_code_from(qr_payload),
      connection_status: connection_status_from(
        connected: connected,
        logged_in: logged_in,
        jid: jid,
        qr_image: qr_image,
        fallback: 'disconnected'
      )
    }
  end

  def format_phone_number(jid)
    digits = extract_digits_from_jid(jid)
    return channel.phone_number if digits.blank?

    "+#{digits}"
  end

  def extract_digits_from_jid(jid)
    return if jid.blank?

    jid.to_s.split('@').first.to_s.split(':').first.to_s.gsub(/\D/, '')
  end

  def current_provider_config
    @current_provider_config ||= channel.provider_config.to_h.deep_stringify_keys
  end

  def client
    @client ||= EvolutionGo::Client.new(channel: channel)
  end

  def safe_fetch
    yield
  rescue EvolutionGo::Client::Error
    nil
  end
end
