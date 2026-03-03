require 'cgi'

class Api::V1::Accounts::Inboxes::WhatsappWebController < Api::V1::Accounts::BaseController
  INSTANCE_NAME_PATTERN = /\A[a-zA-Z0-9_\-]+\z/.freeze
  PHONE_DIGITS_LENGTH = 11
  PHONE_PATTERN = /\A\d{11}\z/.freeze
  INTEGRATION_TYPE = 'whatsapp_web'.freeze
  EVOLUTION_INSTANCE_INTEGRATION = 'WHATSAPP-BAILEYS'.freeze
  DEFAULT_DAYS_LIMIT_IMPORT_MESSAGES = 60
  DEFAULT_QR_DURATION_SECONDS = 45
  RESETTABLE_DISCONNECTION_CODES = [401, 403, 406].freeze

  before_action :set_inbox
  before_action :check_admin_authorization?
  before_action :ensure_api_channel!

  def show
    log_whatsapp_web_action('show')
    render json: {
      config: serialize_settings(current_settings)
    }
  end

  def update
    settings = persist_settings(config_update_params)
    log_whatsapp_web_action('update', phone: settings[:phone], webhook_url: build_evolution_webhook_url(settings))
    render json: { config: serialize_settings(settings) }
  end

  def test_connection
    instances = list_instances
    log_whatsapp_web_action('test_connection', devices_count: instances.length)
    render json: {
      status: 'ok',
      devices_count: instances.length,
      devices: instances
    }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    log_whatsapp_web_action('test_connection_failed', error: e.message)
    render_connector_error(e)
  end

  def setup
    settings = persist_settings(config_update_params)
    settings = persist_settings({ instance_name: resolve_instance_name(settings) }, sync_webhook: false)

    base_url = resolve_chatwoot_base_url
    api_token = resolve_chatwoot_api_token

    instance_response = prepare_instance_for_setup(settings)
    chatwoot_response = upsert_evolution_chatwoot_config(settings, base_url, api_token)
    instance_settings_response = upsert_evolution_instance_settings(settings)
    status_snapshot = build_status_snapshot(settings[:instance_name])

    settings = persist_settings(
      {
        last_setup_error: nil,
        last_setup_at: Time.current.iso8601
      },
      sync_webhook: false
    )
    log_whatsapp_web_action(
      'setup',
      instance_name: settings[:instance_name],
      webhook_url: build_evolution_webhook_url(settings)
    )

    render json: {
      config: serialize_settings(settings),
      setup: {
        device: unwrap_results(instance_response),
        tenant_chatwoot_config: unwrap_results(chatwoot_response),
        instance_settings: unwrap_results(instance_settings_response),
        status: status_snapshot
      }
    }
  rescue StandardError => e
    safe_persist_setup_error(e.message)
    log_whatsapp_web_action('setup_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def devices
    devices = list_instances
    log_whatsapp_web_action('devices', devices_count: devices.length)
    render json: { devices: devices }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    log_whatsapp_web_action('devices_failed', error: e.message)
    render_connector_error(e)
  end

  def status
    instance_name = selected_instance_name
    normalized_status = build_status_snapshot(instance_name)
    log_whatsapp_web_action('status', instance_name: instance_name, state: normalized_status[:state])
    render json: { status: normalized_status }
  rescue StandardError => e
    log_whatsapp_web_action('status_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def login_qr
    settings = current_settings
    instance_name = selected_instance_name

    ensure_runtime_instance!(settings, instance_name: instance_name)
    instance_data = find_instance_by_name(instance_name)
    status_snapshot = build_status_snapshot(instance_name, instance_data: instance_data)
    login_payload =
      if status_snapshot[:is_connecting] || status_snapshot[:is_connected]
        reusable_login_payload(instance_data, status_snapshot: status_snapshot)
      else
        response = connect_instance(instance_name)
        status_snapshot = build_status_snapshot(instance_name)
        normalize_login_payload(response, status_snapshot: status_snapshot)
      end
    log_whatsapp_web_action('login_qr', instance_name: instance_name, state: login_payload[:state])
    render json: { login: login_payload, status: status_snapshot }
  rescue StandardError => e
    log_whatsapp_web_action('login_qr_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def login_code
    settings = current_settings
    instance_name = selected_instance_name
    phone = selected_phone(params[:phone])
    return render json: { error: 'phone is required' }, status: :unprocessable_content if phone.blank?

    ensure_runtime_instance!(settings, instance_name: instance_name)
    instance_data = find_instance_by_name(instance_name)
    status_snapshot = build_status_snapshot(instance_name, instance_data: instance_data)
    current_login_payload = reusable_login_payload(instance_data, status_snapshot: status_snapshot)
    login_payload =
      if status_snapshot[:is_connected]
        current_login_payload
      elsif status_snapshot[:is_connecting] && current_login_payload[:pair_code].present?
        current_login_payload
      else
        response = connect_instance(instance_name, phone: phone, query: { number: phone })
        status_snapshot = build_status_snapshot(instance_name)
        normalize_login_payload(response, status_snapshot: status_snapshot)
      end
    log_whatsapp_web_action('login_code', instance_name: instance_name, phone: phone, pair_code_present: login_payload[:pair_code].present?)
    render json: { login: login_payload, status: status_snapshot }
  rescue StandardError => e
    log_whatsapp_web_action('login_code_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def reconnect
    settings = current_settings
    instance_name = selected_instance_name

    ensure_runtime_instance!(settings, instance_name: instance_name)

    response = evolution_client.post("/instance/restart/#{escaped_instance_name_for(instance_name)}")
    if reconnect_requires_connect?(response)
      response = connect_instance(instance_name, phone: settings[:phone])
    else
      raise_if_connector_payload_error!(response)
    end

    status_snapshot = build_status_snapshot(instance_name)
    log_whatsapp_web_action('reconnect', instance_name: instance_name, state: status_snapshot[:state])
    render json: { reconnect: unwrap_results(response), status: status_snapshot }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    unless disconnected_instance_error?(e)
      log_whatsapp_web_action('reconnect_failed', error: e.message)
      return render_connector_error(e)
    end

    settings = current_settings
    instance_name = selected_instance_name
    ensure_runtime_instance!(settings, instance_name: instance_name)
    response = connect_instance(instance_name, phone: settings[:phone])
    status_snapshot = build_status_snapshot(instance_name)
    log_whatsapp_web_action('reconnect', instance_name: instance_name, fallback: 'connect', state: status_snapshot[:state])
    render json: { reconnect: unwrap_results(response), status: status_snapshot }
  rescue StandardError => e
    log_whatsapp_web_action('reconnect_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def cancel
    instance_name = selected_instance_name
    status_snapshot = build_status_snapshot(instance_name)

    if status_snapshot[:state] == 'missing'
      payload = successful_noop_response('Instance already removed')
      log_whatsapp_web_action('cancel', instance_name: instance_name, noop: true, state: status_snapshot[:state])
      return render json: { cancel: unwrap_results(payload), status: status_snapshot }
    end

    if status_snapshot[:state] == 'close'
      payload = successful_noop_response('Connection attempt already cancelled')
      log_whatsapp_web_action('cancel', instance_name: instance_name, noop: true, state: status_snapshot[:state])
      return render json: { cancel: unwrap_results(payload), status: status_snapshot }
    end

    if status_snapshot[:state] == 'open'
      payload = successful_noop_response('Instance is already connected')
      log_whatsapp_web_action('cancel', instance_name: instance_name, noop: true, state: status_snapshot[:state])
      return render json: { cancel: unwrap_results(payload), status: status_snapshot }
    end

    response = evolution_client.delete("/instance/logout/#{escaped_instance_name_for(instance_name)}")
    response = normalize_noop_response(response, allowed_patterns: ['not connected', 'does not exist'])
    raise_if_connector_payload_error!(response)

    updated_status = build_status_snapshot(instance_name)
    log_whatsapp_web_action('cancel', instance_name: instance_name, state: updated_status[:state])
    render json: { cancel: unwrap_results(response), status: updated_status }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    recovered_status = build_status_snapshot(instance_name)

    if %w[missing close].include?(recovered_status[:state])
      payload = successful_noop_response('Connection cancelled')
      log_whatsapp_web_action(
        'cancel',
        instance_name: instance_name,
        recovered_from_error: true,
        state: recovered_status[:state],
        connector_error: connector_error_message(e)
      )
      return render json: { cancel: unwrap_results(payload), status: recovered_status }
    end

    log_whatsapp_web_action('cancel_failed', error: e.message)
    render_connector_error(e)
  rescue StandardError => e
    log_whatsapp_web_action('cancel_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def logout
    instance_name = selected_instance_name
    status_snapshot = build_status_snapshot(instance_name)

    if %w[missing close unknown].include?(status_snapshot[:state])
      payload = successful_noop_response(status_snapshot[:state] == 'missing' ? 'Instance already removed' : 'Instance already disconnected')
      log_whatsapp_web_action('logout', instance_name: instance_name, noop: true, state: status_snapshot[:state])
      return render json: { logout: unwrap_results(payload), status: status_snapshot }
    end

    response = evolution_client.delete("/instance/logout/#{escaped_instance_name_for(instance_name)}")
    response = normalize_noop_response(response, allowed_patterns: ['not connected', 'does not exist'])
    raise_if_connector_payload_error!(response)

    updated_status = build_status_snapshot(instance_name)
    log_whatsapp_web_action('logout', instance_name: instance_name, state: updated_status[:state])
    render json: { logout: unwrap_results(response), status: updated_status }
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    recovered_status = build_status_snapshot(instance_name)

    if %w[missing close].include?(recovered_status[:state])
      payload = successful_noop_response('Instance logged out')
      log_whatsapp_web_action(
        'logout',
        instance_name: instance_name,
        recovered_from_error: true,
        state: recovered_status[:state],
        connector_error: connector_error_message(e)
      )
      return render json: { logout: unwrap_results(payload), status: recovered_status }
    end

    log_whatsapp_web_action('logout_failed', error: e.message)
    render_connector_error(e)
  rescue StandardError => e
    log_whatsapp_web_action('logout_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def remove_device
    instance_name = selected_instance_name
    response = delete_remote_instance_if_present(instance_name)
    status_snapshot = build_status_snapshot(instance_name)
    log_whatsapp_web_action('remove_device', instance_name: instance_name, state: status_snapshot[:state])
    render json: { remove_device: unwrap_results(response), status: status_snapshot }
  rescue StandardError => e
    log_whatsapp_web_action('remove_device_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def sync
    updated_values = {}
    updated_values[:days_limit_import_messages] = sanitized_days_limit if params.key?(:days_limit) || params.key?(:days_limit_import_messages)
    updated_values[:import_messages] = cast_bool(params[:import_messages], current_settings[:import_messages]) if params.key?(:import_messages)
    settings = updated_values.present? ? persist_settings(updated_values, sync_webhook: false) : current_settings

    runtime = ensure_runtime_instance!(settings, instance_name: settings[:instance_name])
    response = runtime[:chatwoot_response]
    log_whatsapp_web_action(
      'sync',
      instance_name: settings[:instance_name],
      import_messages: settings[:import_messages],
      days_limit_import_messages: settings[:days_limit_import_messages]
    )
    render json: { sync: unwrap_results(response), status: build_status_snapshot(settings[:instance_name]) }
  rescue StandardError => e
    log_whatsapp_web_action('sync_failed', error: e.message)
    render json: { error: e.message }, status: :unprocessable_content
  end

  def sync_status
    instance_name = selected_instance_name
    status = build_status_snapshot(instance_name)
    chatwoot = status[:exists] ? evolution_client.get("/chatwoot/find/#{escaped_instance_name_for(instance_name)}") : {}

    log_whatsapp_web_action('sync_status', instance_name: instance_name)
    render json: {
      sync_status: {
        status: status,
        chatwoot: unwrap_results(chatwoot)
      }
    }
  rescue StandardError => e
    log_whatsapp_web_action('sync_status_failed', error: e.message)
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

  def stored_settings
    attrs = (@inbox.channel.additional_attributes || {}).with_indifferent_access
    raw_settings = (attrs[:whatsapp_web] || {}).with_indifferent_access

    normalize_stored_settings(raw_settings)
  end

  def current_settings
    settings = resolve_settings(stored_settings)
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
      :sign_delimiter,
      :reopen_conversation,
      :conversation_pending,
      :import_contacts,
      :merge_brazil_contacts,
      :import_messages,
      :days_limit_import_messages,
      :msg_call,
      :reject_call,
      :ignore_groups,
      :always_online,
      :read_messages,
      :read_status,
      :sync_full_history,
      ignore_jids: []
    ).to_h.with_indifferent_access

    updates[:evolution_base_url] = updates[:evolution_base_url].to_s.strip if updates.key?(:evolution_base_url)
    updates[:evolution_base_path] = normalize_base_path(updates[:evolution_base_path]) if updates.key?(:evolution_base_path)
    updates[:evolution_api_key] = updates[:evolution_api_key].to_s.strip if updates.key?(:evolution_api_key)
    updates[:phone] = normalize_phone(updates[:phone]) if updates.key?(:phone)
    updates[:instance_name] = updates[:instance_name].to_s.strip if updates.key?(:instance_name)
    updates[:instance_token] = updates[:instance_token].to_s.strip if updates.key?(:instance_token)
    updates[:sign_delimiter] = normalize_sign_delimiter(updates[:sign_delimiter]) if updates.key?(:sign_delimiter)
    updates[:msg_call] = updates[:msg_call].to_s.strip if updates.key?(:msg_call)
    updates[:ignore_jids] = normalize_ignore_jids(updates[:ignore_jids]) if updates.key?(:ignore_jids)

    updates[:sign_msg] = cast_bool(updates[:sign_msg], false) if updates.key?(:sign_msg)
    updates[:reopen_conversation] = cast_bool(updates[:reopen_conversation], false) if updates.key?(:reopen_conversation)
    updates[:conversation_pending] = cast_bool(updates[:conversation_pending], false) if updates.key?(:conversation_pending)
    updates[:import_contacts] = cast_bool(updates[:import_contacts], true) if updates.key?(:import_contacts)
    updates[:merge_brazil_contacts] = cast_bool(updates[:merge_brazil_contacts], false) if updates.key?(:merge_brazil_contacts)
    updates[:import_messages] = cast_bool(updates[:import_messages], true) if updates.key?(:import_messages)
    updates[:days_limit_import_messages] = updates[:days_limit_import_messages].to_i if updates.key?(:days_limit_import_messages)
    updates[:reject_call] = cast_bool(updates[:reject_call], false) if updates.key?(:reject_call)
    updates[:ignore_groups] = cast_bool(updates[:ignore_groups], false) if updates.key?(:ignore_groups)
    updates[:always_online] = cast_bool(updates[:always_online], false) if updates.key?(:always_online)
    updates[:read_messages] = cast_bool(updates[:read_messages], false) if updates.key?(:read_messages)
    updates[:read_status] = cast_bool(updates[:read_status], false) if updates.key?(:read_status)
    updates[:sync_full_history] = cast_bool(updates[:sync_full_history], false) if updates.key?(:sync_full_history)

    updates
  end

  def persist_settings(updates, sync_webhook: true)
    normalized_updates = updates.with_indifferent_access
    ensure_phone_immutable!(normalized_updates)

    raw_settings = stored_settings.merge(normalized_updates)
    raw_settings = normalize_stored_settings(raw_settings)
    settings = resolve_settings(raw_settings)
    settings[:instance_name] = resolve_instance_name(settings)

    validate_settings!(settings)

    attrs = (@inbox.channel.additional_attributes || {}).with_indifferent_access
    attrs[:integration_type] = INTEGRATION_TYPE
    attrs[:whatsapp_web] = persistable_settings(raw_settings, settings)

    channel_updates = { additional_attributes: attrs }
    channel_updates[:webhook_url] = build_evolution_webhook_url(settings) if sync_webhook
    @inbox.channel.update!(channel_updates)
    @inbox.update!(name: settings[:phone]) if @inbox.name != settings[:phone]

    current_settings
  end

  def ensure_phone_immutable!(updates)
    return unless updates.key?(:phone)

    existing_phone = stored_settings[:phone].to_s
    requested_phone = updates[:phone].to_s
    return if existing_phone.blank? || requested_phone.blank? || existing_phone == requested_phone

    raise ArgumentError, 'phone cannot be changed after inbox creation'
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

  def create_or_reuse_instance(settings, instance_name: settings[:instance_name], skip_lookup: false)
    existing = skip_lookup ? nil : find_instance_by_name(instance_name)
    return { 'results' => existing.to_h.merge('already_exists' => true) } if existing.present?

    payload = {
      instanceName: instance_name,
      qrcode: false,
      integration: EVOLUTION_INSTANCE_INTEGRATION
    }
    payload[:token] = settings[:instance_token] if settings[:instance_token].present?

    evolution_client.post('/instance/create', body: payload)
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    raise unless instance_exists_error?(e)

    existing = find_instance_by_name(instance_name)
    { 'results' => existing || { instanceName: instance_name, already_exists: true } }
  end

  def upsert_evolution_chatwoot_config(settings, base_url, api_token, instance_name: settings[:instance_name])
    payload = {
      enabled: true,
      accountId: Current.account.id.to_s,
      token: api_token,
      url: base_url,
      signMsg: settings[:sign_msg],
      signDelimiter: settings[:sign_delimiter],
      reopenConversation: settings[:reopen_conversation],
      conversationPending: settings[:conversation_pending],
      importContacts: settings[:import_contacts],
      importMessages: settings[:import_messages],
      daysLimitImportMessages: settings[:days_limit_import_messages],
      autoCreate: false,
      nameInbox: settings[:phone],
      ignoreJids: evolution_ignore_jids(settings[:ignore_jids])
    }

    evolution_client.post("/chatwoot/set/#{escaped_instance_name_for(instance_name)}", body: payload)
  end

  def upsert_evolution_instance_settings(settings, instance_name: settings[:instance_name])
    payload = {
      rejectCall: settings[:reject_call],
      msgCall: settings[:msg_call],
      groupsIgnore: settings[:ignore_groups],
      alwaysOnline: settings[:always_online],
      readMessages: settings[:read_messages],
      readStatus: settings[:read_status],
      syncFullHistory: settings[:sync_full_history]
    }

    evolution_client.post("/settings/set/#{escaped_instance_name_for(instance_name)}", body: payload)
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

  def escaped_instance_name_for(instance_name)
    CGI.escape(instance_name.to_s)
  end

  def normalize_phone(value)
    value.to_s.gsub(/\D/, '')
  end

  def normalize_sign_delimiter(value)
    value.to_s
  end

  def normalize_ignore_jids(value)
    values =
      case value
      when Array
        value
      when String
        value.split(/[\r\n,]+/)
      else
        Array(value)
      end

    values.map { |jid| normalize_ignore_jid_value(jid) }.reject(&:blank?).uniq
  end

  def normalize_ignore_jid_value(value)
    value.to_s.strip.split('@').first.to_s.gsub(/\D/, '').slice(0, PHONE_DIGITS_LENGTH)
  end

  def evolution_ignore_jids(values)
    normalize_ignore_jids(values).map { |number| "#{number}@s.whatsapp.net" }
  end

  def ensure_phone_uniqueness!(phone)
    return unless duplicate_phone_used?(phone)

    raise ArgumentError, 'phone is already used by another WhatsApp Web inbox'
  end

  def duplicate_phone_used?(phone)
    Channel::Api
      .joins("INNER JOIN inboxes ON inboxes.channel_id = channel_api.id AND inboxes.channel_type = 'Channel::Api'")
      .where(inboxes: { account_id: Current.account.id })
      .where.not(inboxes: { id: @inbox.id })
      .where("channel_api.additional_attributes ->> 'integration_type' = ?", INTEGRATION_TYPE)
      .where("channel_api.additional_attributes -> 'whatsapp_web' ->> 'phone' = ?", phone)
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

  def normalize_stored_settings(settings)
    updated = settings.with_indifferent_access.deep_dup

    updated[:evolution_base_url] = updated[:evolution_base_url].to_s.strip if updated.key?(:evolution_base_url)
    updated.delete(:evolution_base_url) if updated[:evolution_base_url].blank?
    updated[:evolution_base_path] = normalize_base_path(updated[:evolution_base_path]) if updated.key?(:evolution_base_path)
    updated[:evolution_api_key] = updated[:evolution_api_key].to_s.strip if updated.key?(:evolution_api_key)
    updated.delete(:evolution_api_key) if updated[:evolution_api_key].blank?
    updated[:phone] = normalize_phone(updated[:phone]) if updated.key?(:phone)
    updated[:instance_name] = updated[:instance_name].to_s.strip if updated.key?(:instance_name)
    updated[:instance_token] = updated[:instance_token].to_s.strip if updated.key?(:instance_token)
    updated[:sign_delimiter] = normalize_sign_delimiter(updated[:sign_delimiter]) if updated.key?(:sign_delimiter)
    updated.delete(:sign_delimiter) if updated[:sign_delimiter].blank?
    updated[:msg_call] = updated[:msg_call].to_s.strip if updated.key?(:msg_call)
    updated.delete(:msg_call) if updated[:msg_call].blank?
    updated[:ignore_jids] = normalize_ignore_jids(updated[:ignore_jids]) if updated.key?(:ignore_jids)
    updated.delete(:ignore_jids) if updated[:ignore_jids].blank?
    updated[:sign_msg] = cast_bool(updated[:sign_msg], false) if updated.key?(:sign_msg)
    updated[:reopen_conversation] = cast_bool(updated[:reopen_conversation], false) if updated.key?(:reopen_conversation)
    updated[:conversation_pending] = cast_bool(updated[:conversation_pending], false) if updated.key?(:conversation_pending)
    updated[:import_contacts] = cast_bool(updated[:import_contacts], true) if updated.key?(:import_contacts)
    updated[:merge_brazil_contacts] = cast_bool(updated[:merge_brazil_contacts], false) if updated.key?(:merge_brazil_contacts)
    updated[:import_messages] = cast_bool(updated[:import_messages], true) if updated.key?(:import_messages)
    updated[:days_limit_import_messages] = updated[:days_limit_import_messages].to_i if updated.key?(:days_limit_import_messages)
    updated[:reject_call] = cast_bool(updated[:reject_call], false) if updated.key?(:reject_call)
    updated[:ignore_groups] = cast_bool(updated[:ignore_groups], false) if updated.key?(:ignore_groups)
    updated[:always_online] = cast_bool(updated[:always_online], false) if updated.key?(:always_online)
    updated[:read_messages] = cast_bool(updated[:read_messages], false) if updated.key?(:read_messages)
    updated[:read_status] = cast_bool(updated[:read_status], false) if updated.key?(:read_status)
    updated[:sync_full_history] = cast_bool(updated[:sync_full_history], false) if updated.key?(:sync_full_history)
    updated[:last_setup_error] = updated[:last_setup_error].to_s if updated.key?(:last_setup_error)
    updated[:last_setup_at] = updated[:last_setup_at].to_s if updated.key?(:last_setup_at)

    updated
  end

  def resolve_settings(settings)
    defaults = default_settings
    updated = defaults.merge(settings.with_indifferent_access)

    updated[:evolution_base_url] = updated[:evolution_base_url].to_s.strip.presence || defaults[:evolution_base_url]
    updated[:evolution_base_path] = normalize_base_path(updated[:evolution_base_path])
    updated[:evolution_api_key] = updated[:evolution_api_key].to_s.strip.presence || defaults[:evolution_api_key]
    updated[:phone] = normalize_phone(updated[:phone])
    updated[:instance_name] = updated[:instance_name].to_s.strip
    updated[:instance_token] = updated[:instance_token].to_s.strip
    updated[:sign_delimiter] = updated[:sign_delimiter].to_s.presence || defaults[:sign_delimiter]
    updated[:msg_call] = updated[:msg_call].to_s
    updated[:ignore_jids] = normalize_ignore_jids(updated[:ignore_jids])
    updated[:sign_msg] = cast_bool(updated[:sign_msg], defaults[:sign_msg])
    updated[:reopen_conversation] = cast_bool(updated[:reopen_conversation], defaults[:reopen_conversation])
    updated[:conversation_pending] = cast_bool(updated[:conversation_pending], defaults[:conversation_pending])
    updated[:import_contacts] = cast_bool(updated[:import_contacts], defaults[:import_contacts])
    updated[:merge_brazil_contacts] = cast_bool(updated[:merge_brazil_contacts], defaults[:merge_brazil_contacts])
    updated[:import_messages] = cast_bool(updated[:import_messages], defaults[:import_messages])
    updated[:reject_call] = cast_bool(updated[:reject_call], defaults[:reject_call])
    updated[:ignore_groups] = cast_bool(updated[:ignore_groups], defaults[:ignore_groups])
    updated[:always_online] = cast_bool(updated[:always_online], defaults[:always_online])
    updated[:read_messages] = cast_bool(updated[:read_messages], defaults[:read_messages])
    updated[:read_status] = cast_bool(updated[:read_status], defaults[:read_status])
    updated[:sync_full_history] = cast_bool(updated[:sync_full_history], defaults[:sync_full_history])
    updated[:days_limit_import_messages] =
      updated[:days_limit_import_messages].to_i.positive? ? updated[:days_limit_import_messages].to_i : defaults[:days_limit_import_messages]
    updated[:last_setup_error] = updated[:last_setup_error].to_s
    updated[:last_setup_at] = updated[:last_setup_at].to_s

    updated
  end

  def persistable_settings(raw_settings, resolved_settings)
    raw_settings
      .merge(
        phone: resolved_settings[:phone],
        instance_name: resolved_settings[:instance_name]
      )
      .except(:chatwoot_webhook_url, :merge_brazil_contacts, :organization, :logo)
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
      sign_delimiter: ENV.fetch('WHATSAPP_WEB_SIGN_DELIMITER', '\\n').to_s,
      msg_call: ENV.fetch('WHATSAPP_WEB_MSG_CALL', '').to_s,
      ignore_jids: normalize_ignore_jids(ENV.fetch('WHATSAPP_WEB_IGNORE_JIDS', '').to_s),
      sign_msg: cast_bool(ENV.fetch('WHATSAPP_WEB_SIGN_MSG', false), false),
      reopen_conversation: cast_bool(ENV.fetch('WHATSAPP_WEB_REOPEN_CONVERSATION', false), false),
      conversation_pending: cast_bool(ENV.fetch('WHATSAPP_WEB_CONVERSATION_PENDING', false), false),
      import_contacts: cast_bool(ENV.fetch('WHATSAPP_WEB_IMPORT_CONTACTS', true), true),
      merge_brazil_contacts: cast_bool(ENV.fetch('WHATSAPP_WEB_MERGE_BRAZIL_CONTACTS', false), false),
      import_messages: cast_bool(ENV.fetch('WHATSAPP_WEB_IMPORT_MESSAGES', true), true),
      reject_call: cast_bool(ENV.fetch('WHATSAPP_WEB_REJECT_CALL', false), false),
      ignore_groups: cast_bool(ENV.fetch('WHATSAPP_WEB_IGNORE_GROUPS', false), false),
      always_online: cast_bool(ENV.fetch('WHATSAPP_WEB_ALWAYS_ONLINE', false), false),
      read_messages: cast_bool(ENV.fetch('WHATSAPP_WEB_READ_MESSAGES', false), false),
      read_status: cast_bool(ENV.fetch('WHATSAPP_WEB_READ_STATUS', false), false),
      sync_full_history: cast_bool(ENV.fetch('WHATSAPP_WEB_SYNC_FULL_HISTORY', false), false),
      days_limit_import_messages: begin
        value = ENV.fetch('WHATSAPP_WEB_DAYS_LIMIT_IMPORT_MESSAGES', DEFAULT_DAYS_LIMIT_IMPORT_MESSAGES).to_i
        value.positive? ? value : DEFAULT_DAYS_LIMIT_IMPORT_MESSAGES
      end,
      last_setup_error: '',
      last_setup_at: ''
    }.with_indifferent_access
  end

  def build_evolution_webhook_url(settings, instance_name: resolve_instance_name(settings))
    base_url = settings[:evolution_base_url].to_s.strip
    return @inbox.channel.webhook_url if base_url.blank?

    base_path = normalize_base_path(settings[:evolution_base_path])

    "#{base_url.chomp('/')}#{base_path}/chatwoot/webhook/#{escaped_instance_name_for(instance_name)}"
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

  def normalize_status_payload(response, instance_name:, instance_data: nil)
    raw = unwrap_results(response)
    remote_instance = normalize_remote_instance(instance_data)
    state = extract_state(raw)
    state = remote_instance[:connectionStatus].to_s if state == 'unknown' && remote_instance[:connectionStatus].present?
    state = 'missing' if state == 'unknown' && remote_instance.blank?
    is_connected = state == 'open'
    is_connecting = state == 'connecting'
    disconnection_reason_code = remote_instance[:disconnectionReasonCode]
    disconnection_message = extract_disconnection_message(remote_instance[:disconnectionObject])

    {
      instance_name: instance_name,
      state: state,
      exists: remote_instance.present?,
      is_connected: is_connected,
      is_logged_in: is_connected,
      is_connecting: is_connecting,
      requires_pairing: !is_connected,
      can_request_qr: state != 'open',
      can_request_pair_code: state != 'open',
      can_reconnect: !is_connecting,
      can_logout: remote_instance.present? && state == 'open',
      can_cancel: remote_instance.present? && is_connecting,
      can_remove_device: remote_instance.present?,
      can_reset: true,
      disconnection_reason_code: disconnection_reason_code,
      disconnection_message: disconnection_message,
      owner_jid: remote_instance[:ownerJid],
      profile_name: remote_instance[:profileName],
      evolution_instance_id: remote_instance[:id]
    }
  end

  def normalize_login_payload(response, status_snapshot: nil)
    raw = unwrap_results(response)
    qrcode = extract_qrcode_payload(raw)
    current_status = status_snapshot || normalize_status_payload(raw, instance_name: selected_instance_name)
    state = extract_state(raw)
    state = current_status[:state] if state == 'unknown'

    {
      qr_link: qrcode[:base64],
      qr_duration: DEFAULT_QR_DURATION_SECONDS,
      pair_code: qrcode[:pairing_code],
      state: state,
      is_connected: current_status[:is_connected],
      is_logged_in: current_status[:is_logged_in]
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
    message.include?('not connected') || missing_instance_message?(message)
  end

  def reconnect_requires_connect?(response)
    payload = unwrap_results(response)
    return false unless payload.is_a?(Hash)

    data = payload.with_indifferent_access
    return true if data[:error] == true

    message = data[:message].to_s.downcase
    message.include?('not connected') || missing_instance_message?(message)
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

  def prepare_instance_for_setup(settings)
    instance_name = settings[:instance_name]
    existing = find_instance_by_name(instance_name)
    needs_reset = stale_instance?(existing)
    delete_remote_instance_if_present(instance_name, instance_data: existing) if needs_reset

    return { 'results' => existing.to_h.merge('already_exists' => true) } if existing.present? && !needs_reset

    create_or_reuse_instance(settings, instance_name: instance_name, skip_lookup: true)
  end

  def ensure_runtime_instance!(settings, instance_name:)
    existing = find_instance_by_name(instance_name)
    needs_reset = stale_instance?(existing)
    delete_remote_instance_if_present(instance_name, instance_data: existing) if needs_reset

    instance_response =
      if existing.blank? || needs_reset
        create_or_reuse_instance(settings, instance_name: instance_name, skip_lookup: true)
      end

    chatwoot_response = upsert_evolution_chatwoot_config(
      settings,
      resolve_chatwoot_base_url,
      resolve_chatwoot_api_token,
      instance_name: instance_name
    )
    instance_settings_response = upsert_evolution_instance_settings(
      settings,
      instance_name: instance_name
    )

    {
      instance_response: instance_response,
      chatwoot_response: chatwoot_response,
      instance_settings_response: instance_settings_response
    }
  end

  def build_status_snapshot(instance_name, instance_data: nil)
    current_instance = instance_data.presence || find_instance_by_name(instance_name)
    return normalize_status_payload({}, instance_name: instance_name, instance_data: nil) if current_instance.blank?

    response = fetch_instance_status(instance_name)
    normalize_status_payload(response, instance_name: instance_name, instance_data: current_instance)
  end

  def reusable_login_payload(instance_data, status_snapshot:)
    payload_source = status_snapshot[:is_connecting] ? instance_data : {}
    normalize_login_payload(payload_source || {}, status_snapshot: status_snapshot)
  end

  def connect_instance(instance_name, phone: nil, query: nil)
    request_query = query || (phone.present? ? { number: phone } : nil)
    response = evolution_client.get("/instance/connect/#{escaped_instance_name_for(instance_name)}", query: request_query)
    return response unless connector_payload_error?(response)

    if missing_instance_response?(response)
      settings = current_settings
      ensure_runtime_instance!(settings, instance_name: instance_name)
      response = evolution_client.get("/instance/connect/#{escaped_instance_name_for(instance_name)}", query: request_query)
    end

    raise_if_connector_payload_error!(response)
    response
  end

  def delete_remote_instance_if_present(instance_name, instance_data: nil)
    current_instance = instance_data.presence || find_instance_by_name(instance_name)
    return successful_noop_response('Instance already removed') if current_instance.blank?

    response = evolution_client.delete("/instance/delete/#{escaped_instance_name_for(instance_name)}")
    response = normalize_noop_response(response, allowed_patterns: ['does not exist'])
    raise_if_connector_payload_error!(response)
    response
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    raise unless disconnected_instance_error?(e)

    successful_noop_response('Instance already removed')
  end

  def connector_payload_error?(response)
    payload = unwrap_results(response)
    payload.is_a?(Hash) && payload.with_indifferent_access[:error] == true
  end

  def raise_if_connector_payload_error!(response)
    return response unless connector_payload_error?(response)

    message = payload_error_message(response)
    raise WhatsappWeb::ConnectorClient::RequestError.new(
      message.presence || 'Connector request failed',
      response_body: unwrap_results(response)
    )
  end

  def payload_error_message(response)
    payload = unwrap_results(response)
    return connector_error_message(WhatsappWeb::ConnectorClient::RequestError.new('', response_body: payload)) if payload.is_a?(Hash)

    payload.to_s
  end

  def normalize_noop_response(response, allowed_patterns:)
    return response unless connector_payload_error?(response)

    message = payload_error_message(response).to_s.downcase
    return response unless allowed_patterns.any? { |pattern| message.include?(pattern) }

    successful_noop_response(payload_error_message(response))
  end

  def successful_noop_response(message)
    {
      'status' => 'SUCCESS',
      'error' => false,
      'response' => {
        'message' => message.to_s
      }
    }
  end

  def missing_instance_response?(response)
    payload_error_message(response).to_s.downcase.then { |message| missing_instance_message?(message) }
  end

  def missing_instance_message?(message)
    message.include?('does not exist') || message.include?('instance not found') || message.include?('not found')
  end

  def stale_instance?(instance_data)
    remote_instance = normalize_remote_instance(instance_data)
    return false if remote_instance.blank?
    return false unless remote_instance[:connectionStatus].to_s == 'close'

    code = remote_instance[:disconnectionReasonCode].to_i
    return true if RESETTABLE_DISCONNECTION_CODES.include?(code)

    extract_disconnection_message(remote_instance[:disconnectionObject]).to_s.downcase.include?('bad session')
  end

  def normalize_remote_instance(instance_data)
    return {}.with_indifferent_access unless instance_data.is_a?(Hash)

    instance_data.with_indifferent_access
  end

  def extract_disconnection_message(raw_value)
    payload =
      case raw_value
      when Hash
        raw_value.with_indifferent_access
      when String
        parsed = JSON.parse(raw_value)
        parsed.is_a?(Hash) ? parsed.with_indifferent_access : {}.with_indifferent_access
      else
        {}.with_indifferent_access
      end

    payload.dig(:error, :output, :payload, :message).to_s.presence ||
      payload.dig(:error, :message).to_s.presence ||
      payload[:message].to_s
  rescue JSON::ParserError
    raw_value.to_s
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
      sign_delimiter: settings[:sign_delimiter],
      msg_call: settings[:msg_call],
      reopen_conversation: settings[:reopen_conversation],
      conversation_pending: settings[:conversation_pending],
      import_contacts: settings[:import_contacts],
      import_messages: settings[:import_messages],
      days_limit_import_messages: settings[:days_limit_import_messages],
      ignore_jids: settings[:ignore_jids],
      reject_call: settings[:reject_call],
      ignore_groups: settings[:ignore_groups],
      always_online: settings[:always_online],
      read_messages: settings[:read_messages],
      read_status: settings[:read_status],
      sync_full_history: settings[:sync_full_history],
      last_setup_error: settings[:last_setup_error],
      last_setup_at: settings[:last_setup_at],
      config_sources: configuration_sources
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

  def configuration_sources
    raw_settings = stored_settings

    {
      evolution_base_url: config_source_for(raw_settings, :evolution_base_url),
      evolution_base_path: config_source_for(raw_settings, :evolution_base_path),
      evolution_api_key: config_source_for(raw_settings, :evolution_api_key),
      instance_token: config_source_for(raw_settings, :instance_token),
      sign_msg: config_source_for(raw_settings, :sign_msg),
      sign_delimiter: config_source_for(raw_settings, :sign_delimiter),
      msg_call: config_source_for(raw_settings, :msg_call),
      reopen_conversation: config_source_for(raw_settings, :reopen_conversation),
      conversation_pending: config_source_for(raw_settings, :conversation_pending),
      import_contacts: config_source_for(raw_settings, :import_contacts),
      import_messages: config_source_for(raw_settings, :import_messages),
      days_limit_import_messages: config_source_for(raw_settings, :days_limit_import_messages),
      ignore_jids: config_source_for(raw_settings, :ignore_jids),
      reject_call: config_source_for(raw_settings, :reject_call),
      ignore_groups: config_source_for(raw_settings, :ignore_groups),
      always_online: config_source_for(raw_settings, :always_online),
      read_messages: config_source_for(raw_settings, :read_messages),
      read_status: config_source_for(raw_settings, :read_status),
      sync_full_history: config_source_for(raw_settings, :sync_full_history),
      webhook_secret: ENV.fetch('WHATSAPP_WEB_WEBHOOK_SECRET', '').present? ? 'env' : 'unset',
      webhook_timeout: ENV.fetch('WHATSAPP_WEB_WEBHOOK_TIMEOUT', '').present? ? 'env' : 'global',
      webhook_host_allowlist: ENV.fetch('WHATSAPP_WEB_WEBHOOK_ALLOWED_HOSTS', '').present? ? 'env' : 'unset'
    }
  end

  def config_source_for(raw_settings, key)
    raw_settings.key?(key) ? 'stored' : 'default'
  end

  def log_whatsapp_web_action(action, extra = {})
    context = {
      account_id: Current.account.id,
      inbox_id: @inbox.id,
      channel_id: @inbox.channel_id,
      instance_name: current_settings[:instance_name].presence,
      integration_type: INTEGRATION_TYPE
    }.merge(extra).compact

    Rails.logger.info("[WHATSAPP_WEB] #{action} #{context.to_json}")
  end
end

Api::V1::Accounts::Inboxes::WhatsappWebController.prepend_mod_with('Api::V1::Accounts::Inboxes::WhatsappWebController')
