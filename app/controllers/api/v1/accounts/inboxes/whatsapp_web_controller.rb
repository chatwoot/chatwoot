require 'cgi'

class Api::V1::Accounts::Inboxes::WhatsappWebController < Api::V1::Accounts::BaseController
  INSTANCE_NAME_PATTERN = /\A[a-zA-Z0-9_\-]+\z/.freeze
  PHONE_DIGITS_LENGTH = 11
  PHONE_PATTERN = /\A\d{11}\z/.freeze
  INTEGRATION_TYPE = 'whatsapp_web'.freeze
  EVOLUTION_INSTANCE_INTEGRATION = 'WHATSAPP-BAILEYS'.freeze
  DEFAULT_DAYS_LIMIT_IMPORT_MESSAGES = 60
  DEFAULT_QR_DURATION_SECONDS = 45

  before_action :set_inbox
  before_action :check_admin_authorization?
  before_action :ensure_api_channel!

  def show
    render json: {
      config: serialize_settings(current_settings)
    }
  end

  def update
    settings = persist_settings(config_update_params)
    render json: { config: serialize_settings(settings) }
  end

  def test_connection
    instances = list_instances
    render json: {
      status: 'ok',
      devices_count: instances.length,
      devices: instances
    }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    render_connector_error(e)
  end

  def setup
    settings = persist_settings(config_update_params)
    settings[:instance_name] = resolve_instance_name(settings)
    settings = persist_settings(settings, sync_webhook: false)

    base_url = resolve_chatwoot_base_url
    api_token = resolve_chatwoot_api_token

    instance_response = create_or_reuse_instance(settings)
    chatwoot_response = upsert_evolution_chatwoot_config(settings, base_url, api_token)
    status_response = fetch_instance_status(settings[:instance_name])

    settings = persist_settings(
      {
        last_setup_error: nil,
        last_setup_at: Time.current.iso8601
      },
      sync_webhook: false
    )

    render json: {
      config: serialize_settings(settings),
      setup: {
        device: unwrap_results(instance_response),
        tenant_chatwoot_config: unwrap_results(chatwoot_response),
        status: normalize_status_payload(status_response, instance_name: settings[:instance_name])
      }
    }
  rescue StandardError => e
    safe_persist_setup_error(e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def devices
    render json: { devices: list_instances }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    render_connector_error(e)
  end

  def status
    instance_name = selected_instance_name
    response = fetch_instance_status(instance_name)
    render json: { status: normalize_status_payload(response, instance_name: instance_name) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def login_qr
    phone = selected_phone(params[:phone])
    query = phone.present? ? { number: phone } : nil

    response = evolution_client.get("/instance/connect/#{escaped_instance_name}", query: query)
    render json: { login: normalize_login_payload(response) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def login_code
    phone = selected_phone(params[:phone])
    return render json: { error: 'phone is required' }, status: :unprocessable_content if phone.blank?

    response = evolution_client.get(
      "/instance/connect/#{escaped_instance_name}",
      query: { number: phone }
    )
    render json: { login: normalize_login_payload(response) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def reconnect
    response = evolution_client.post("/instance/restart/#{escaped_instance_name}")
    response = evolution_client.get("/instance/connect/#{escaped_instance_name}") if reconnect_requires_connect?(response)
    render json: { reconnect: unwrap_results(response) }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    return render_connector_error(e) unless disconnected_instance_error?(e)

    response = evolution_client.get("/instance/connect/#{escaped_instance_name}")
    render json: { reconnect: unwrap_results(response) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def logout
    response = evolution_client.delete("/instance/logout/#{escaped_instance_name}")
    render json: { logout: unwrap_results(response) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def remove_device
    response = evolution_client.delete("/instance/delete/#{escaped_instance_name}")
    render json: { remove_device: unwrap_results(response) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def sync
    updated_values = {}
    updated_values[:days_limit_import_messages] = sanitized_days_limit if params.key?(:days_limit) || params.key?(:days_limit_import_messages)
    updated_values[:import_messages] = cast_bool(params[:import_messages], current_settings[:import_messages]) if params.key?(:import_messages)
    settings = updated_values.present? ? persist_settings(updated_values, sync_webhook: false) : current_settings

    response = upsert_evolution_chatwoot_config(settings, resolve_chatwoot_base_url, resolve_chatwoot_api_token)
    render json: { sync: unwrap_results(response) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def sync_status
    instance_name = selected_instance_name
    status = fetch_instance_status(instance_name)
    chatwoot = evolution_client.get("/chatwoot/find/#{CGI.escape(instance_name)}")

    render json: {
      sync_status: {
        status: normalize_status_payload(status, instance_name: instance_name),
        chatwoot: unwrap_results(chatwoot)
      }
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
  end

  def ensure_api_channel!
    return if @inbox.api?

    render json: { error: 'WhatsApp Web is only available for API inbox channels' }, status: :unprocessable_content
  end

  def current_settings
    attrs = (@inbox.channel.additional_attributes || {}).with_indifferent_access
    defaults = default_settings
    settings = defaults.merge((attrs[:whatsapp_web] || {}).with_indifferent_access)

    settings[:evolution_base_url] = settings[:evolution_base_url].to_s.strip.presence || defaults[:evolution_base_url]
    settings[:evolution_base_path] = normalize_base_path(settings[:evolution_base_path].presence || defaults[:evolution_base_path])
    settings[:evolution_api_key] = settings[:evolution_api_key].to_s.strip.presence || defaults[:evolution_api_key]
    settings[:phone] = normalize_phone(settings[:phone].presence || defaults[:phone])
    settings[:instance_name] = settings[:instance_name].to_s.strip
    settings[:instance_token] = settings[:instance_token].to_s.strip
    settings[:sign_msg] = cast_bool(settings[:sign_msg], defaults[:sign_msg])
    settings[:reopen_conversation] = cast_bool(settings[:reopen_conversation], defaults[:reopen_conversation])
    settings[:conversation_pending] = cast_bool(settings[:conversation_pending], defaults[:conversation_pending])
    settings[:import_contacts] = cast_bool(settings[:import_contacts], defaults[:import_contacts])
    settings[:merge_brazil_contacts] = cast_bool(settings[:merge_brazil_contacts], defaults[:merge_brazil_contacts])
    settings[:import_messages] = cast_bool(settings[:import_messages], defaults[:import_messages])
    settings[:days_limit_import_messages] =
      settings[:days_limit_import_messages].to_i.positive? ? settings[:days_limit_import_messages].to_i : defaults[:days_limit_import_messages]
    settings[:last_setup_error] = settings[:last_setup_error].to_s
    settings[:last_setup_at] = settings[:last_setup_at].to_s
    settings[:chatwoot_webhook_url] = build_evolution_webhook_url(settings)

    settings
  end

  def config_update_params
    updates = params.permit(
      :evolution_base_url,
      :evolution_base_path,
      :evolution_api_key,
      :phone,
      :instance_name,
      :instance_token,
      :sign_msg,
      :reopen_conversation,
      :conversation_pending,
      :import_contacts,
      :merge_brazil_contacts,
      :import_messages,
      :days_limit_import_messages
    ).to_h.with_indifferent_access

    updates[:evolution_base_url] = updates[:evolution_base_url].to_s.strip if updates.key?(:evolution_base_url)
    updates[:evolution_base_path] = normalize_base_path(updates[:evolution_base_path]) if updates.key?(:evolution_base_path)
    updates[:evolution_api_key] = updates[:evolution_api_key].to_s.strip if updates.key?(:evolution_api_key)
    updates[:phone] = normalize_phone(updates[:phone]) if updates.key?(:phone)
    updates[:instance_name] = updates[:instance_name].to_s.strip if updates.key?(:instance_name)
    updates[:instance_token] = updates[:instance_token].to_s.strip if updates.key?(:instance_token)

    updates[:sign_msg] = cast_bool(updates[:sign_msg], false) if updates.key?(:sign_msg)
    updates[:reopen_conversation] = cast_bool(updates[:reopen_conversation], false) if updates.key?(:reopen_conversation)
    updates[:conversation_pending] = cast_bool(updates[:conversation_pending], false) if updates.key?(:conversation_pending)
    updates[:import_contacts] = cast_bool(updates[:import_contacts], true) if updates.key?(:import_contacts)
    updates[:merge_brazil_contacts] = cast_bool(updates[:merge_brazil_contacts], false) if updates.key?(:merge_brazil_contacts)
    updates[:import_messages] = cast_bool(updates[:import_messages], true) if updates.key?(:import_messages)
    updates[:days_limit_import_messages] = updates[:days_limit_import_messages].to_i if updates.key?(:days_limit_import_messages)

    updates
  end

  def persist_settings(updates, sync_webhook: true)
    settings = current_settings.merge(updates.with_indifferent_access)
    settings = apply_default_fallbacks(settings)
    settings[:instance_name] = resolve_instance_name(settings)

    validate_settings!(settings)

    attrs = (@inbox.channel.additional_attributes || {}).with_indifferent_access
    attrs[:integration_type] = INTEGRATION_TYPE
    attrs[:whatsapp_web] = settings.except(:chatwoot_webhook_url)

    channel_updates = { additional_attributes: attrs }
    channel_updates[:webhook_url] = build_evolution_webhook_url(settings) if sync_webhook
    @inbox.channel.update!(channel_updates)
    @inbox.update!(name: settings[:phone]) if @inbox.name != settings[:phone]

    current_settings
  end

  def validate_settings!(settings)
    if settings[:evolution_base_url].blank?
      raise ArgumentError, 'evolution_base_url is required'
    end

    validate_url!(settings[:evolution_base_url])

    if settings[:evolution_api_key].blank?
      raise ArgumentError, 'evolution_api_key is required'
    end

    if settings[:phone].blank?
      raise ArgumentError, 'phone is required'
    end

    unless settings[:phone].match?(PHONE_PATTERN)
      raise ArgumentError, "phone must contain exactly #{PHONE_DIGITS_LENGTH} digits"
    end

    ensure_phone_uniqueness!(settings[:phone])

    if settings[:instance_name].blank?
      raise ArgumentError, 'instance_name is required'
    end

    unless settings[:instance_name].match?(INSTANCE_NAME_PATTERN)
      raise ArgumentError, 'instance_name may contain only letters, numbers, underscore, and hyphen'
    end

    if settings[:days_limit_import_messages].to_i <= 0
      raise ArgumentError, 'days_limit_import_messages must be greater than 0'
    end
  end

  def validate_url!(value)
    uri = URI.parse(value)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    raise ArgumentError, 'evolution_base_url must be a valid http/https URL'
  rescue URI::InvalidURIError
    raise ArgumentError, 'evolution_base_url must be a valid URL'
  end

  def evolution_client
    settings = current_settings

    WhatsappWeb::ConnectorClient.new(
      base_url: settings[:evolution_base_url],
      base_path: settings[:evolution_base_path],
      api_key: settings[:evolution_api_key]
    )
  end

  def create_or_reuse_instance(settings)
    existing = find_instance_by_name(settings[:instance_name])
    return { 'results' => existing.to_h.merge('already_exists' => true) } if existing.present?

    payload = {
      instanceName: settings[:instance_name],
      qrcode: false,
      integration: EVOLUTION_INSTANCE_INTEGRATION
    }
    payload[:token] = settings[:instance_token] if settings[:instance_token].present?

    evolution_client.post('/instance/create', body: payload)
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    raise unless instance_exists_error?(e)

    existing = find_instance_by_name(settings[:instance_name])
    { 'results' => existing || { instanceName: settings[:instance_name], already_exists: true } }
  end

  def upsert_evolution_chatwoot_config(settings, base_url, api_token)
    payload = {
      enabled: true,
      accountId: Current.account.id.to_s,
      token: api_token,
      url: base_url,
      signMsg: settings[:sign_msg],
      reopenConversation: settings[:reopen_conversation],
      conversationPending: settings[:conversation_pending],
      importContacts: settings[:import_contacts],
      mergeBrazilContacts: settings[:merge_brazil_contacts],
      importMessages: settings[:import_messages],
      daysLimitImportMessages: settings[:days_limit_import_messages],
      autoCreate: false,
      nameInbox: settings[:phone]
    }

    evolution_client.post("/chatwoot/set/#{CGI.escape(settings[:instance_name])}", body: payload)
  end

  def fetch_instance_status(instance_name)
    evolution_client.get("/instance/connectionState/#{CGI.escape(instance_name)}")
  end

  def list_instances
    response = evolution_client.get('/instance/fetchInstances')
    payload = unwrap_results(response)

    return payload if payload.is_a?(Array)
    return payload['instances'] if payload.is_a?(Hash) && payload['instances'].is_a?(Array)

    []
  end

  def find_instance_by_name(instance_name)
    list_instances.find do |instance|
      data = instance.is_a?(Hash) ? instance.with_indifferent_access : {}.with_indifferent_access
      data[:name] == instance_name || data[:instanceName] == instance_name
    end
  end

  def resolve_instance_name(settings)
    return "cw_#{Current.account.id}_#{settings[:phone]}" if settings[:phone].present?
    return settings[:instance_name] if settings[:instance_name].present?

    "cw_#{Current.account.id}_#{@inbox.id}"
  end

  def selected_phone(explicit_phone)
    phone = normalize_phone(explicit_phone)
    return phone if phone.present?

    current_settings[:phone].to_s
  end

  def selected_instance_name
    explicit = params[:instance_name].to_s.strip
    return explicit if explicit.present?

    stored = current_settings[:instance_name].to_s.strip
    return stored if stored.present?

    raise ArgumentError, 'instance_name is required'
  end

  def escaped_instance_name
    CGI.escape(selected_instance_name)
  end

  def normalize_phone(value)
    value.to_s.gsub(/\D/, '')
  end

  def ensure_phone_uniqueness!(phone)
    return unless duplicate_phone_used?(phone)

    raise ArgumentError, 'phone is already used by another WhatsApp Web inbox'
  end

  def duplicate_phone_used?(phone)
    Channel::Api
      .joins("INNER JOIN inboxes ON inboxes.channel_id = channel_apis.id AND inboxes.channel_type = 'Channel::Api'")
      .where(inboxes: { account_id: Current.account.id })
      .where.not(inboxes: { id: @inbox.id })
      .where("channel_apis.additional_attributes ->> 'integration_type' = ?", INTEGRATION_TYPE)
      .where("channel_apis.additional_attributes -> 'whatsapp_web' ->> 'phone' = ?", phone)
      .exists?
  end

  def resolve_chatwoot_api_token
    token = Current.user&.access_token&.token
    return token if token.present?

    Current.user.create_access_token
    Current.user.reload.access_token.token
  end

  def resolve_chatwoot_base_url
    configured_url = ENV.fetch('FRONTEND_URL', '').to_s.strip
    configured_url = request.base_url if configured_url.blank?
    configured_url.chomp('/')
  end

  def apply_default_fallbacks(settings)
    defaults = default_settings
    updated = settings.with_indifferent_access

    updated[:evolution_base_url] = updated[:evolution_base_url].to_s.strip.presence || defaults[:evolution_base_url]
    updated[:evolution_base_path] = normalize_base_path(updated[:evolution_base_path].to_s.presence || defaults[:evolution_base_path])
    updated[:evolution_api_key] = updated[:evolution_api_key].to_s.strip.presence || defaults[:evolution_api_key]
    updated[:phone] = normalize_phone(updated[:phone].presence || defaults[:phone])
    updated[:instance_name] = updated[:instance_name].to_s.strip
    updated[:instance_token] = updated[:instance_token].to_s.strip.presence || defaults[:instance_token]
    updated[:sign_msg] = cast_bool(updated[:sign_msg], defaults[:sign_msg])
    updated[:reopen_conversation] = cast_bool(updated[:reopen_conversation], defaults[:reopen_conversation])
    updated[:conversation_pending] = cast_bool(updated[:conversation_pending], defaults[:conversation_pending])
    updated[:import_contacts] = cast_bool(updated[:import_contacts], defaults[:import_contacts])
    updated[:merge_brazil_contacts] = cast_bool(updated[:merge_brazil_contacts], defaults[:merge_brazil_contacts])
    updated[:import_messages] = cast_bool(updated[:import_messages], defaults[:import_messages])
    updated[:days_limit_import_messages] =
      updated[:days_limit_import_messages].to_i.positive? ? updated[:days_limit_import_messages].to_i : defaults[:days_limit_import_messages]

    updated
  end

  def default_settings
    evolution_base_url = ENV.fetch('WHATSAPP_WEB_EVOLUTION_BASE_URL', '').to_s.strip
    evolution_base_url = ENV.fetch('EVOLUTION_SERVER_URL', '').to_s.strip if evolution_base_url.blank?

    evolution_base_path = ENV.fetch('WHATSAPP_WEB_EVOLUTION_BASE_PATH', '').to_s

    evolution_api_key = ENV.fetch('WHATSAPP_WEB_EVOLUTION_API_KEY', '').to_s.strip
    evolution_api_key = ENV.fetch('EVOLUTION_AUTHENTICATION_API_KEY', '').to_s.strip if evolution_api_key.blank?
    evolution_api_key = ENV.fetch('AUTHENTICATION_API_KEY', '').to_s.strip if evolution_api_key.blank?

    {
      evolution_base_url: evolution_base_url,
      evolution_base_path: normalize_base_path(evolution_base_path),
      evolution_api_key: evolution_api_key,
      phone: '',
      instance_name: '',
      instance_token: ENV.fetch('WHATSAPP_WEB_INSTANCE_TOKEN', '').to_s.strip,
      sign_msg: cast_bool(ENV.fetch('WHATSAPP_WEB_SIGN_MSG', false), false),
      reopen_conversation: cast_bool(ENV.fetch('WHATSAPP_WEB_REOPEN_CONVERSATION', false), false),
      conversation_pending: cast_bool(ENV.fetch('WHATSAPP_WEB_CONVERSATION_PENDING', false), false),
      import_contacts: cast_bool(ENV.fetch('WHATSAPP_WEB_IMPORT_CONTACTS', true), true),
      merge_brazil_contacts: cast_bool(ENV.fetch('WHATSAPP_WEB_MERGE_BRAZIL_CONTACTS', false), false),
      import_messages: cast_bool(ENV.fetch('WHATSAPP_WEB_IMPORT_MESSAGES', true), true),
      days_limit_import_messages: begin
        value = ENV.fetch('WHATSAPP_WEB_DAYS_LIMIT_IMPORT_MESSAGES', DEFAULT_DAYS_LIMIT_IMPORT_MESSAGES).to_i
        value.positive? ? value : DEFAULT_DAYS_LIMIT_IMPORT_MESSAGES
      end,
      last_setup_error: '',
      last_setup_at: ''
    }.with_indifferent_access
  end

  def build_evolution_webhook_url(settings)
    base_url = settings[:evolution_base_url].to_s.strip
    return @inbox.channel.webhook_url if base_url.blank?

    base_path = normalize_base_path(settings[:evolution_base_path])
    instance_name = resolve_instance_name(settings)

    "#{base_url.chomp('/')}#{base_path}/chatwoot/webhook/#{CGI.escape(instance_name)}"
  end

  def normalize_base_path(path)
    normalized = path.to_s.strip
    return '' if normalized.blank?

    normalized = "/#{normalized}" unless normalized.start_with?('/')
    normalized.chomp('/')
  end

  def sanitized_days_limit
    value = params[:days_limit].to_i
    value = params[:days_limit_import_messages].to_i if value <= 0
    return value if value.positive?

    current_settings[:days_limit_import_messages]
  end

  def cast_bool(value, fallback)
    return fallback if value.nil?

    ActiveModel::Type::Boolean.new.cast(value)
  end

  def unwrap_results(response)
    return response unless response.is_a?(Hash)

    response['results'] || response
  end

  def normalize_status_payload(response, instance_name:)
    raw = unwrap_results(response)
    state = extract_state(raw)
    is_connected = state == 'open'

    {
      instance_name: instance_name,
      state: state,
      is_connected: is_connected,
      is_logged_in: is_connected
    }
  end

  def normalize_login_payload(response)
    raw = unwrap_results(response)
    qrcode = extract_qrcode_payload(raw)

    {
      qr_link: qrcode[:base64],
      qr_duration: DEFAULT_QR_DURATION_SECONDS,
      pair_code: qrcode[:pairing_code],
      state: extract_state(raw)
    }.compact
  end

  def extract_qrcode_payload(raw)
    payload = raw.is_a?(Hash) ? raw.with_indifferent_access : {}.with_indifferent_access
    qrcode = if payload[:qrcode].is_a?(Hash)
               payload[:qrcode].with_indifferent_access
             else
               payload
             end

    {
      base64: qrcode[:base64].presence || qrcode[:qr_link].presence,
      pairing_code: qrcode[:pairingCode].presence || qrcode[:pair_code].presence
    }
  end

  def extract_state(raw)
    payload = raw.is_a?(Hash) ? raw.with_indifferent_access : {}.with_indifferent_access
    payload.dig(:instance, :state).to_s.presence || payload[:state].to_s.presence || payload[:connectionStatus].to_s.presence || 'unknown'
  end

  def instance_exists_error?(error)
    message = connector_error_message(error).downcase
    message.include?('already') || message.include?('exists') || message.include?('duplicate')
  end

  def disconnected_instance_error?(error)
    message = connector_error_message(error).downcase
    message.include?('not connected') || message.include?('does not exist')
  end

  def reconnect_requires_connect?(response)
    payload = unwrap_results(response)
    return false unless payload.is_a?(Hash)

    data = payload.with_indifferent_access
    return true if data[:error] == true

    message = data[:message].to_s.downcase
    message.include?('not connected') || message.include?('does not exist')
  end

  def connector_error_message(error)
    body = error.respond_to?(:response_body) ? error.response_body : nil
    if body.is_a?(Hash)
      body = body.with_indifferent_access
      return body[:message].to_s if body[:message].present?

      nested = body[:response]
      if nested.is_a?(Hash)
        nested = nested.with_indifferent_access
        nested_message = nested[:message]
        return nested_message.join(', ') if nested_message.is_a?(Array) && nested_message.any?
        return nested_message.to_s if nested_message.present?
        return nested[:error].to_s if nested[:error].present?
      end

      return body[:error].to_s if body[:error].present?
    end

    error.message.to_s
  end

  def safe_persist_setup_error(message)
    persist_settings(
      {
        last_setup_error: message,
        last_setup_at: Time.current.iso8601
      },
      sync_webhook: false
    )
  rescue StandardError
    nil
  end

  def serialize_settings(settings)
    {
      evolution_base_url: settings[:evolution_base_url],
      evolution_base_path: settings[:evolution_base_path],
      phone: settings[:phone],
      instance_name: settings[:instance_name],
      instance_token_configured: settings[:instance_token].present?,
      sign_msg: settings[:sign_msg],
      reopen_conversation: settings[:reopen_conversation],
      conversation_pending: settings[:conversation_pending],
      import_contacts: settings[:import_contacts],
      merge_brazil_contacts: settings[:merge_brazil_contacts],
      import_messages: settings[:import_messages],
      days_limit_import_messages: settings[:days_limit_import_messages],
      last_setup_error: settings[:last_setup_error],
      last_setup_at: settings[:last_setup_at]
    }.merge(
      evolution_api_key_configured: settings[:evolution_api_key].present?,
      chatwoot_webhook_url: build_evolution_webhook_url(settings),
      inbox_id: @inbox.id,
      account_id: Current.account.id
    )
  end

  def render_connector_error(error)
    render json: { error: connector_error_message(error) }, status: :unprocessable_content
  end
end

Api::V1::Accounts::Inboxes::WhatsappWebController.prepend_mod_with('Api::V1::Accounts::Inboxes::WhatsappWebController')
