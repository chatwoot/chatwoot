# frozen_string_literal: true

# Api::V1::Accounts::EvolutionInboxesController
#
# Handles Evolution API-backed WhatsApp inbox operations (Baileys only).
# All operations are scoped to the current account and resolve Evolution
# instance names from inbox metadata - never accepting instance names from clients.
#
class Api::V1::Accounts::EvolutionInboxesController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization!
  before_action :validate_evolution_enabled!, except: [:status]
  before_action :fetch_inbox, except: [:create, :status]
  before_action :validate_evolution_inbox!, except: [:create, :status]

  # POST /api/v1/accounts/:account_id/evolution/inboxes
  # Creates a new Evolution-backed WhatsApp inbox (Baileys)
  def create
    provisioner = EvolutionApi::InboxProvisioner.new(
      account: Current.account,
      inbox_name: provision_params[:inbox_name]
    )

    @inbox = provisioner.provision!
    render json: inbox_response(@inbox), status: :created
  rescue EvolutionApi::InboxProvisioner::ProvisioningError => e
    Rails.logger.error("Evolution inbox provisioning failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace.present?
    render json: { error: format_error_message(e) }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Unexpected error during Evolution inbox provisioning: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace.present?
    render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  end

  # GET /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/chatwoot
  # Returns Evolution's Chatwoot integration settings
  def chatwoot_settings
    settings = evolution_client.find_chatwoot_integration(instance_name: evolution_instance_name)
    render json: sanitize_chatwoot_settings(settings)
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PUT /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/chatwoot
  # Updates Evolution's Chatwoot integration settings (excluding fixed fields)
  def update_chatwoot_settings
    chatwoot_config = build_chatwoot_update_config

    evolution_client.set_chatwoot_integration(
      instance_name: evolution_instance_name,
      chatwoot_config: chatwoot_config
    )

    settings = evolution_client.find_chatwoot_integration(instance_name: evolution_instance_name)
    render json: sanitize_chatwoot_settings(settings)
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/connection
  # Returns the Evolution instance connection state
  def connection
    state = evolution_client.connection_state(instance_name: evolution_instance_name)
    render json: state
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/qrcode
  # Returns QR code for Baileys instances to connect
  def qrcode
    qr_data = evolution_client.connect_instance(instance_name: evolution_instance_name)
    render json: qr_data
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/enable_integration
  # Enables Evolution→Chatwoot integration after WhatsApp connection (Baileys)
  # This should be called after the user scans the QR code and WhatsApp is connected
  def enable_integration
    # Verify the instance is connected before enabling integration
    state = evolution_client.connection_state(instance_name: evolution_instance_name)
    unless state.dig('instance', 'state') == 'open'
      render json: { error: 'WhatsApp is not connected. Please scan the QR code first.' }, status: :unprocessable_entity
      return
    end

    # Enable Chatwoot integration with autoCreate:false (we already created the inbox)
    evolution_client.set_chatwoot_integration(
      instance_name: evolution_instance_name,
      chatwoot_config: build_enable_integration_config
    )

    render json: { message: 'Integration enabled successfully', connected: true }
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/restart
  # Restarts the Evolution instance
  def restart
    result = evolution_client.restart_instance(instance_name: evolution_instance_name)
    render json: result
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/logout
  # Disconnects the Evolution instance from WhatsApp (logout)
  def logout
    result = evolution_client.logout_instance(instance_name: evolution_instance_name)
    render json: result
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/refresh
  # Refreshes the connection (reconnect for Baileys)
  def refresh
    result = evolution_client.connect_instance(instance_name: evolution_instance_name)
    render json: result
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/instance_settings
  # Returns instance settings (reject calls, groups ignore, always online, etc.)
  def instance_settings
    settings = evolution_client.find_settings(instance_name: evolution_instance_name)
    render json: settings
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PUT /api/v1/accounts/:account_id/evolution/inboxes/:inbox_id/instance_settings
  # Updates instance settings
  def update_instance_settings
    settings = evolution_client.set_settings(
      instance_name: evolution_instance_name,
      settings: instance_settings_params
    )
    render json: settings
  rescue EvolutionApi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/evolution/status
  # Returns whether Evolution API is enabled and configured
  def status
    enabled = evolution_enabled?
    configured = enabled && evolution_configured?

    render json: {
      enabled: enabled,
      configured: configured
    }
  end

  private

  def check_admin_authorization!
    raise Pundit::NotAuthorizedError unless Current.user&.administrator?
  end

  def validate_evolution_enabled!
    return if evolution_enabled?

    render json: { error: 'Evolution API is not enabled for this installation' }, status: :forbidden
  end

  def evolution_enabled?
    config = InstallationConfig.find_by(name: 'EVOLUTION_API_ENABLED')
    config&.value == true || config&.value == 'true'
  end

  def evolution_configured?
    url = InstallationConfig.find_by(name: 'EVOLUTION_API_URL')&.value
    key = InstallationConfig.find_by(name: 'EVOLUTION_API_KEY')&.value
    url.present? && key.present?
  end

  def fetch_inbox
    inbox_id = params[:inbox_id] || params[:id]
    @inbox = Current.account.inboxes.find(inbox_id)
    authorize @inbox, :show?
  end

  def validate_evolution_inbox!
    return if evolution_inbox?

    render json: { error: 'This inbox is not an Evolution API inbox' }, status: :unprocessable_entity
  end

  def evolution_inbox?
    return false unless @inbox.channel_type == 'Channel::Api'

    evolution_instance_name.present?
  end

  def evolution_instance_name
    @inbox.channel.additional_attributes&.dig('evolution_instance_name')
  end

  def evolution_client
    @evolution_client ||= EvolutionApi::Client.new
  end

  def provision_params
    params.require(:evolution_inbox).permit(:inbox_name)
  end

  def chatwoot_update_params
    params.permit(
      :sign_msg,
      :sign_delimiter,
      :reopen_conversation,
      :conversation_pending,
      :merge_brazil_contacts,
      :import_contacts,
      :import_messages,
      :days_limit_import_messages
    )
  end

  def instance_settings_params
    permitted = %i[reject_call msg_call groups_ignore always_online read_messages read_status sync_full_history]

    if params[:evolution_inbox].present?
      params.require(:evolution_inbox).permit(*permitted).to_h.symbolize_keys
    else
      params.permit(*permitted).to_h.symbolize_keys
    end
  end

  def build_chatwoot_update_config
    config = chatwoot_update_params.to_h.symbolize_keys

    # Add fixed fields that should never change (resolved from current installation)
    config[:url] = chatwoot_reachable_url
    config[:account_id] = Current.account.id
    config[:token] = integration_user_token
    config[:name_inbox] = @inbox.name
    config[:auto_create] = false

    config
  end

  def build_enable_integration_config
    {
      url: chatwoot_reachable_url,
      account_id: Current.account.id,
      token: integration_user_token,
      name_inbox: @inbox.name,
      auto_create: false,
      enabled: true,
      sign_msg: true,
      reopen_conversation: true,
      conversation_pending: false,
      merge_brazil_contacts: true,
      import_contacts: true,
      import_messages: true,
      days_limit_import_messages: 3
    }
  end

  # Returns a Chatwoot URL reachable by Evolution API
  def chatwoot_reachable_url
    if Rails.env.development?
      frontend_url = ENV['FRONTEND_URL']
      if frontend_url&.include?('localhost') || frontend_url&.include?('127.0.0.1')
        host_ip = `ipconfig getifaddr en0 2>/dev/null`.strip
        host_ip = '192.168.0.22' if host_ip.blank?
        "http://#{host_ip}:3000"
      else
        frontend_url
      end
    else
      ENV.fetch('FRONTEND_URL', nil) || Rails.application.routes.url_helpers.root_url
    end
  end

  def integration_user_token
    user = User.find_by(email: EvolutionApi::InboxProvisioner::INTEGRATION_USER_EMAIL)
    user&.access_token&.token
  end

  def sanitize_chatwoot_settings(settings)
    settings = settings.dup if settings.is_a?(Hash)
    settings&.except('token', :token)
  end

  def inbox_response(inbox)
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type,
      evolution: {
        instance_name: inbox.channel.additional_attributes['evolution_instance_name'],
        channel: inbox.channel.additional_attributes['evolution_channel'],
        url: inbox.channel.additional_attributes['evolution_url']
      }
    }
  end

  def format_error_message(error)
    message = error.message

    if message.include?('Validation failed:')
      message.sub(/^.*Validation failed:\s*/, 'Validation error: ')
    elsif message.include?('Failed to provision Evolution inbox:')
      message
    else
      "Failed to create Evolution inbox: #{message}"
    end
  end
end

