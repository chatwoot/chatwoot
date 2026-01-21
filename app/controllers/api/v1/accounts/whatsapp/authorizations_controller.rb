class Api::V1::Accounts::Whatsapp::AuthorizationsController < Api::V1::Accounts::BaseController
  before_action :fetch_and_validate_inbox, if: -> { params[:inbox_id].present? }

  # POST /api/v1/accounts/:account_id/whatsapp/authorization
  # Handles both initial authorization and reauthorization
  # If inbox_id is present in params, it performs reauthorization
  def create
    log_whatsapp_configuration
    validate_embedded_signup_params!
    channel = process_embedded_signup
    render_success_response(channel.inbox)
  rescue StandardError => e
    render_error_response(e)
  end

  private

  def log_whatsapp_configuration
    account = Current.account
    whatsapp_settings = account.whatsapp_settings if account.respond_to?(:whatsapp_settings)

    Rails.logger.info '=' * 80
    Rails.logger.info '🚀 WHATSAPP AUTHORIZATION REQUEST'
    Rails.logger.info '=' * 80
    Rails.logger.info "📋 Account: #{account.name} (ID: #{account.id})"
    Rails.logger.info "👤 User: #{current_user.email} (ID: #{current_user.id})"
    Rails.logger.info "🔄 Type: #{params[:inbox_id].present? ? 'Reauthorization' : 'New Authorization'}"
    Rails.logger.info "📦 Inbox ID: #{params[:inbox_id]}" if params[:inbox_id].present?
    Rails.logger.info ''
    Rails.logger.info '📱 WHATSAPP CONFIGURATION:'

    if whatsapp_settings
      Rails.logger.info "  ✅ Account-level settings found (ID: #{whatsapp_settings.id})"
      Rails.logger.info "  📱 App ID: #{whatsapp_settings.app_id&.slice(0, 8)}... (#{whatsapp_settings.app_id&.length} chars)"
      Rails.logger.info "  🔐 App Secret: #{whatsapp_settings.app_secret.present? ? '✓ Set' : '✗ Missing'} (#{whatsapp_settings.app_secret&.length} chars)"
      Rails.logger.info "  ⚙️  Configuration ID: #{whatsapp_settings.configuration_id}"
      Rails.logger.info "  🔑 Verify Token: #{whatsapp_settings.verify_token&.slice(0, 8)}... (#{whatsapp_settings.verify_token&.length} chars)"
      Rails.logger.info "  📊 API Version: #{whatsapp_settings.api_version}"
    else
      Rails.logger.info '  ⚠️  No account-level settings found - using global config'
      Rails.logger.info "  📱 Global App ID: #{GlobalConfigService.load('WHATSAPP_APP_ID', 'NOT_SET')}"
      Rails.logger.info "  🔐 Global App Secret: #{ENV['WHATSAPP_APP_SECRET'].present? ? '✓ Set' : '✗ Missing'}"
      Rails.logger.info "  ⚙️  Global Configuration ID: #{GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', 'NOT_SET')}"
      Rails.logger.info "  📊 Global API Version: #{GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')}"
    end

    Rails.logger.info ''
    Rails.logger.info '📥 REQUEST PARAMS:'
    Rails.logger.info "  🔑 Code: #{params[:code].present? ? '✓ Received' : '✗ Missing'} (#{params[:code]&.length} chars)"
    Rails.logger.info "  🏢 Business ID: #{params[:business_id]}"
    Rails.logger.info "  📞 WABA ID: #{params[:waba_id]}"
    Rails.logger.info "  📱 Phone Number ID: #{params[:phone_number_id]}" if params[:phone_number_id].present?
    Rails.logger.info '=' * 80
  end

  def process_embedded_signup
    service = Whatsapp::EmbeddedSignupService.new(
      account: Current.account,
      params: params.permit(:code, :business_id, :waba_id, :phone_number_id).to_h.symbolize_keys,
      inbox_id: params[:inbox_id]
    )
    service.perform
  end

  def fetch_and_validate_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    validate_reauthorization_required
  end

  def validate_reauthorization_required
    return if @inbox.channel.reauthorization_required? || can_upgrade_to_embedded_signup?

    render json: {
      success: false,
      message: I18n.t('inbox.reauthorization.not_required')
    }, status: :unprocessable_entity
  end

  def can_upgrade_to_embedded_signup?
    channel = @inbox.channel
    return false unless channel.provider == 'whatsapp_cloud'

    true
  end

  def render_success_response(inbox)
    response = {
      success: true,
      id: inbox.id,
      name: inbox.name,
      channel_type: 'whatsapp'
    }
    response[:message] = I18n.t('inbox.reauthorization.success') if params[:inbox_id].present?
    render json: response
  end

  def render_error_response(error)
    Rails.logger.error "[WHATSAPP AUTHORIZATION] Embedded signup error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render json: {
      success: false,
      error: error.message
    }, status: :unprocessable_entity
  end

  def validate_embedded_signup_params!
    missing_params = []
    missing_params << 'code' if params[:code].blank?
    missing_params << 'business_id' if params[:business_id].blank?
    missing_params << 'waba_id' if params[:waba_id].blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
