class Api::V1::Accounts::WhapiChannelsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox, only: [:qr_code, :retry_webhook]
  before_action :ensure_whapi_partner_feature_enabled

  rescue_from CustomExceptions::RateLimitExceeded do |exception|
    correlation_id = request.request_id || SecureRandom.uuid
    Rails.logger.warn "[WhapiPartner][RateLimit][#{correlation_id}] #{exception.message}"
    render json: { 
      message: exception.message, 
      correlation_id: correlation_id 
    }, status: :too_many_requests
  end

  # POST /api/v1/accounts/:account_id/whapi_channels
  def create
    correlation_id = request.request_id || SecureRandom.uuid
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.start', account_id: Current.account.id,
                                                                correlation_id: correlation_id)

    name = whapi_channel_params[:name].to_s.strip
    if name.blank?
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.invalid', reason: 'missing_name',
                                                                  account_id: Current.account.id, correlation_id: correlation_id)
      render json: { message: 'name is required', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Basic input validation & sanitization
    # Allow letters, numbers, spaces, hyphens and underscores. Enforce length 2..80
    unless name.match?(/\A[\p{Alnum} _-]{2,80}\z/u)
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.invalid', reason: 'invalid_name',
                                                                  account_id: Current.account.id, correlation_id: correlation_id)
      render json: { message: 'invalid name', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    service = Whatsapp::Partner::WhapiPartnerService.new

    # Determine project id with multiple fallbacks
    # 1) explicit param, 2) installation default via env, 3) partner API projects list
    explicit_project_id = whapi_channel_params[:project_id].presence
    default_project_id = ENV['WHAPI_PARTNER_DEFAULT_PROJECT_ID'].presence

    projects = begin
      service.fetch_projects
    rescue CustomExceptions::RateLimitExceeded => e
      Rails.logger.warn "[WhapiPartner][#{correlation_id}] Project fetch rate limited: #{e.message}"
      raise e # Re-raise to be handled by rescue_from
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.warn "[WhapiPartner][#{correlation_id}] Project fetch timeout: #{e.message}"
      [] # Empty array is acceptable for timeout - user can retry
    rescue HTTParty::Error, Net::HTTPError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Project fetch HTTP error: #{e.message}"
      [] # Empty array for HTTP errors - fallback to env defaults
    rescue JSON::ParserError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Project fetch JSON parse error: #{e.message}"
      [] # Empty array for parsing errors - API response malformed
    rescue StandardError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Unexpected project fetch error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Re-raise unknown errors to fail fast and alert monitoring
      raise e
    end
    first_project = Array(projects).first
    project_list_id = first_project.is_a?(Hash) ? first_project['id'] : nil

    project_id = explicit_project_id || default_project_id || project_list_id
    unless project_id.present?
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.unavailable', reason: 'no_projects',
                                                                  account_id: Current.account.id, correlation_id: correlation_id)
      render json: { message: 'No partner projects available', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Generate environment-specific webhook URL
    webhook_service = Whatsapp::WebhookUrlService.new
    webhook_url = webhook_service.generate_webhook_url

    channel_info = begin
      service.create_channel(name: name, project_id: project_id)
    rescue CustomExceptions::RateLimitExceeded => e
      Rails.logger.warn "[WhapiPartner][#{correlation_id}] Channel creation rate limited: #{e.message}"
      raise e # Re-raise to be handled by rescue_from
    rescue StandardError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Channel creation failed: #{e.message}"
      raise e
    end
    whapi_channel_id = channel_info['id']
    whapi_channel_token = channel_info['token']

    provider_config = {
      'api_key' => whapi_channel_token,
      'whapi_channel_id' => whapi_channel_id,
      'whapi_channel_token' => whapi_channel_token,
      'webhook_url' => webhook_url,
      'connection_status' => 'pending',
      'onboarding' => {
        'created_at' => Time.current.iso8601
      }
    }

    ActiveRecord::Base.transaction do
      channel = Current.account.whatsapp_channels.create!(
        phone_number: "pending:#{whapi_channel_id}",
        provider: 'whapi',
        provider_config: provider_config
      )

      @inbox = Current.account.inboxes.build(name: name, channel: channel)
      @inbox.save!
    end

    # Configure webhook at channel level (critical for message sync) - moved to background job
    Whatsapp::Whapi::WebhookSetupJob.perform_later(@inbox.channel.id)

    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.success', account_id: Current.account.id,
                                                                inbox_id: @inbox.id, channel_id: @inbox.channel_id, correlation_id: correlation_id)

    render 'api/v1/accounts/inboxes/show', format: :json, status: :ok
  rescue StandardError => e
    Rails.logger.error "[WhapiPartner][#{correlation_id}] whapi_channel creation failed: #{e.message}"
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.error', account_id: Current.account.id, error: e.class.name,
                                                                message: e.message, correlation_id: correlation_id)
    render json: { message: e.message, correlation_id: correlation_id }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whapi_channels/:id/qr_code
  def qr_code
    correlation_id = request.request_id || SecureRandom.uuid
    channel = @inbox.channel
    unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whapi'
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.invalid_inbox', account_id: Current.account.id, inbox_id: @inbox.id,
                                                                  correlation_id: correlation_id)
      render json: { message: 'Not a WHAPI WhatsApp inbox', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Use config objects for accessing channel token
    channel_token = channel.provider_config_object.whapi_channel_token
    if channel_token.blank?
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.missing_token', account_id: Current.account.id, inbox_id: @inbox.id,
                                                                  correlation_id: correlation_id)
      render json: { message: 'Channel token missing', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    service = Whatsapp::Partner::WhapiPartnerService.new
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.request', account_id: Current.account.id, inbox_id: @inbox.id,
                                                                correlation_id: correlation_id)

    begin
      qr_payload = service.generate_qr_code(channel_token: channel_token)
    rescue CustomExceptions::RateLimitExceeded => e
      Rails.logger.warn "[WhapiPartner][#{correlation_id}] QR code generation rate limited: #{e.message}"
      raise e # Re-raise to be handled by rescue_from
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] QR code generation timeout: #{e.message}"
      render json: { message: 'QR code generation timed out. Please try again.', correlation_id: correlation_id },
             status: :service_unavailable and return
    rescue HTTParty::Error, Net::HTTPError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] QR code generation HTTP error: #{e.message}"
      render json: { message: 'QR code generation failed. Please try again.', correlation_id: correlation_id },
             status: :service_unavailable and return
    rescue JSON::ParserError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] QR code generation JSON parse error: #{e.message}"
      render json: { message: 'Invalid response from service. Please try again.', correlation_id: correlation_id },
             status: :service_unavailable and return
    rescue StandardError => e
      # Handle the special case of already authenticated channels
      raise e unless e.message.include?('already authenticated')

      # Channel is already authenticated, sync phone number and return success
      config_object = channel.provider_config_object
      config_object.update_connection_status('connected')

      # Schedule phone number sync in background (non-blocking)
      Whatsapp::Whapi::PhoneSyncJob.perform_later(@inbox.channel.id)
      Rails.logger.info "[WhapiPartner][#{correlation_id}] Phone sync scheduled in background"

      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.already_authenticated', account_id: Current.account.id,
                                                                  inbox_id: @inbox.id, correlation_id: correlation_id)
      render json: {
        authenticated: true,
        message: 'WhatsApp account successfully connected!',
        correlation_id: correlation_id
      }, status: :ok and return
    end

    # update last_qr_at for polling/expiry hints
    channel.provider_config_object.update_qr_timestamp

    # Throttle hints for polling: minimum 15s, cap retries client side
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.success', account_id: Current.account.id, inbox_id: @inbox.id,
                                                                correlation_id: correlation_id)
    render json: {
      image_base64: qr_payload['image_base64'],
      expires_in: qr_payload['expires_in'] || 20,
      poll_in: 15,
      correlation_id: correlation_id
    }, status: :ok
  end

  # POST /api/v1/accounts/:account_id/whapi_channels/:id/retry_webhook
  def retry_webhook
    correlation_id = request.request_id || SecureRandom.uuid
    channel = @inbox.channel

    unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whapi'
      render json: { message: 'Not a WHAPI WhatsApp inbox', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Use config objects for accessing channel token
    channel_token = channel.provider_config_object.whapi_channel_token
    if channel_token.blank?
      render json: { message: 'Channel token missing', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Generate environment-specific webhook URL, include phone number if available
    webhook_service = Whatsapp::WebhookUrlService.new
    phone_number = extract_phone_number_from_channel(channel)
    webhook_url = webhook_service.generate_webhook_url(phone_number: phone_number)
    service = Whatsapp::Partner::WhapiPartnerService.new

    begin
      service.retry_webhook_setup(channel_token: channel_token, webhook_url: webhook_url)

      # Update provider config to indicate webhook setup succeeded
      channel.provider_config_object.set_webhook_configured(webhook_url)

      Rails.logger.info "[WhapiPartner][#{correlation_id}] Webhook retry successful"
      render json: {
        message: 'Webhook configured successfully',
        webhook_url: webhook_url,
        correlation_id: correlation_id
      }, status: :ok

    rescue Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Webhook retry timeout: #{e.message}"
      channel.provider_config_object.set_webhook_retry_info("Timeout: #{e.message}")
      render json: {
        message: 'Webhook configuration timed out. Please try again.',
        correlation_id: correlation_id
      }, status: :service_unavailable
    rescue HTTParty::Error, Net::HTTPError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Webhook retry HTTP error: #{e.message}"
      channel.provider_config_object.set_webhook_retry_info("HTTP Error: #{e.message}")
      render json: {
        message: 'Webhook configuration failed due to network error. Please try again.',
        correlation_id: correlation_id
      }, status: :service_unavailable
    rescue JSON::ParserError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Webhook retry JSON parse error: #{e.message}"
      channel.provider_config_object.set_webhook_retry_info("JSON Parse Error: #{e.message}")
      render json: {
        message: 'Invalid response from service. Please try again.',
        correlation_id: correlation_id
      }, status: :service_unavailable
    rescue StandardError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Webhook retry unexpected error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      channel.provider_config_object.set_webhook_retry_info("Unknown Error: #{e.message}")
      render json: {
        message: "Webhook configuration failed: #{e.message}",
        correlation_id: correlation_id
      }, status: :unprocessable_entity
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def extract_phone_number_from_channel(channel)
    return nil unless channel.is_a?(Channel::Whatsapp)

    phone_number = channel.phone_number
    return nil if phone_number.blank? || phone_number.start_with?('pending:')

    phone_number
  end

  def whapi_channel_params
    return params.require(:whapi_channel).permit(:name, :project_id) if params[:whapi_channel].present?

    params.permit(:name, :project_id)
  end

  def ensure_whapi_partner_feature_enabled
    return if Current.account&.feature_enabled?('channel_whatsapp_whapi_partner')

    render json: { message: 'Feature not enabled' }, status: :forbidden
  end
end
