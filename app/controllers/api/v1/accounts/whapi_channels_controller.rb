class Api::V1::Accounts::WhapiChannelsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox, only: [:qr_code, :retry_webhook]
  before_action :ensure_whapi_partner_feature_enabled

  # POST /api/v1/accounts/:account_id/whapi_channels
  def create
    correlation_id = request.request_id || SecureRandom.uuid
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.start', account_id: Current.account.id, correlation_id: correlation_id)

    name = whapi_channel_params[:name].to_s.strip
    if name.blank?
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.invalid', reason: 'missing_name', account_id: Current.account.id, correlation_id: correlation_id)
      render json: { message: 'name is required', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Basic input validation & sanitization
    # Allow letters, numbers, spaces, hyphens and underscores. Enforce length 2..80
    unless name.match?(/\A[\p{Alnum} _-]{2,80}\z/u)
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.invalid', reason: 'invalid_name', account_id: Current.account.id, correlation_id: correlation_id)
      render json: { message: 'invalid name', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    service = Whatsapp::Partner::WhapiPartnerService.new

    # Determine project id with multiple fallbacks
    # 1) explicit param, 2) installation default via env, 3) partner API projects list
    explicit_project_id = whapi_channel_params[:project_id].presence
    default_project_id = ENV['WHAPI_PARTNER_DEFAULT_PROJECT_ID'].presence

    projects = begin
      service.fetch_projects
    rescue StandardError
      []
    end
    first_project = Array(projects).first
    project_list_id = first_project.is_a?(Hash) ? first_project['id'] : nil

    project_id = explicit_project_id || default_project_id || project_list_id
    unless project_id.present?
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.unavailable', reason: 'no_projects', account_id: Current.account.id, correlation_id: correlation_id)
      render json: { message: 'No partner projects available', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    # Generate environment-specific webhook URL
    webhook_service = Whatsapp::WebhookUrlService.new
    webhook_url = webhook_service.generate_webhook_url

    channel_info = service.create_channel(name: name, project_id: project_id)
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

    # Configure webhook at channel level (critical for message sync)
    webhook_configured = false
    begin
      service.update_channel_webhook(channel_token: whapi_channel_token, webhook_url: webhook_url)
      webhook_configured = true
      Rails.logger.info "[WhapiPartner][#{correlation_id}] Webhook configured successfully"
    rescue StandardError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] update_channel_webhook failed: #{e.message}"
      # Update provider config to indicate webhook setup failed
      provider_config['webhook_status'] = 'failed'
      provider_config['webhook_error'] = e.message
      provider_config['webhook_retry_needed'] = true
      @inbox.channel.update!(provider_config: provider_config)
    end

    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.success', account_id: Current.account.id, inbox_id: @inbox.id, channel_id: @inbox.channel_id, correlation_id: correlation_id)

    render 'api/v1/accounts/inboxes/show', format: :json, status: :ok
  rescue StandardError => e
    Rails.logger.error "[WhapiPartner][#{correlation_id}] whapi_channel creation failed: #{e.message}"
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'create_channel.error', account_id: Current.account.id, error: e.class.name, message: e.message, correlation_id: correlation_id)
    render json: { message: e.message, correlation_id: correlation_id }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whapi_channels/:id/qr_code
  def qr_code
    correlation_id = request.request_id || SecureRandom.uuid
    channel = @inbox.channel
    unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whapi'
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.invalid_inbox', account_id: Current.account.id, inbox_id: @inbox.id, correlation_id: correlation_id)
      render json: { message: 'Not a WHAPI WhatsApp inbox', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    channel_token = channel.provider_config&.[]('whapi_channel_token') || channel.provider_config&.[]('api_key')
    if channel_token.blank?
      ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.missing_token', account_id: Current.account.id, inbox_id: @inbox.id, correlation_id: correlation_id)
      render json: { message: 'Channel token missing', correlation_id: correlation_id }, status: :unprocessable_entity and return
    end

    service = Whatsapp::Partner::WhapiPartnerService.new
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.request', account_id: Current.account.id, inbox_id: @inbox.id, correlation_id: correlation_id)
    
    begin
      qr_payload = service.generate_qr_code(channel_token: channel_token)
    rescue StandardError => e
      if e.message.include?('already authenticated')
        # Channel is already authenticated, sync phone number and return success
        provider_config = channel.provider_config || {}
        provider_config['connection_status'] = 'connected'
        
        # Try to sync the phone number now that it's authenticated
        begin
          sync_result = service.sync_channel_phone_number(channel_token: channel_token)
          if sync_result[:success]
            channel.update!(phone_number: sync_result[:phone_number])
            provider_config['phone_number'] = sync_result[:phone_number]
            provider_config['phone_synced_at'] = Time.current.iso8601
            provider_config['user_status'] = sync_result[:status]
            Rails.logger.info "[WhapiPartner][#{correlation_id}] Phone number auto-synced: #{sync_result[:phone_number]}"
            
            # Update webhook URL with phone number
            begin
              new_webhook_url = service.update_webhook_with_phone_number(
                channel_token: channel_token,
                phone_number: sync_result[:phone_number]
              )
              provider_config['webhook_url'] = new_webhook_url
              provider_config['webhook_updated_with_phone'] = true
              provider_config['webhook_updated_at'] = Time.current.iso8601
              Rails.logger.info "[WhapiPartner][#{correlation_id}] Webhook updated with phone number, new URL: #{new_webhook_url}"
            rescue StandardError => webhook_error
              Rails.logger.warn "[WhapiPartner][#{correlation_id}] Webhook update with phone number failed: #{webhook_error.message}"
              provider_config['webhook_phone_update_error'] = webhook_error.message
            end
          end
        rescue StandardError => sync_error
          Rails.logger.warn "[WhapiPartner][#{correlation_id}] Auto phone sync failed: #{sync_error.message}"
        end
        
        channel.update!(provider_config: provider_config)
        
        ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.already_authenticated', account_id: Current.account.id, inbox_id: @inbox.id, correlation_id: correlation_id)
        render json: { 
          authenticated: true, 
          message: 'WhatsApp account successfully connected!',
          correlation_id: correlation_id 
        }, status: :ok and return
      else
        raise e
      end
    end

    # update last_qr_at for polling/expiry hints
    provider_config = channel.provider_config || {}
    onboarding = provider_config['onboarding'] || {}
    onboarding['last_qr_at'] = Time.current.iso8601
    provider_config['onboarding'] = onboarding
    channel.update!(provider_config: provider_config)

    # Throttle hints for polling: minimum 15s, cap retries client side
    ActiveSupport::Notifications.instrument('whapi.onboarding', action: 'qr.success', account_id: Current.account.id, inbox_id: @inbox.id, correlation_id: correlation_id)
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

    channel_token = channel.provider_config&.[]('whapi_channel_token') || channel.provider_config&.[]('api_key')
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
      provider_config = channel.provider_config || {}
      provider_config['webhook_status'] = 'configured'
      provider_config['webhook_url'] = webhook_url
      provider_config['webhook_retry_needed'] = false
      provider_config.delete('webhook_error')
      provider_config['webhook_configured_at'] = Time.current.iso8601
      channel.update!(provider_config: provider_config)
      
      Rails.logger.info "[WhapiPartner][#{correlation_id}] Webhook retry successful"
      render json: { 
        message: 'Webhook configured successfully',
        webhook_url: webhook_url,
        correlation_id: correlation_id 
      }, status: :ok
      
    rescue StandardError => e
      Rails.logger.error "[WhapiPartner][#{correlation_id}] Webhook retry failed: #{e.message}"
      
      # Update provider config with error details
      provider_config = channel.provider_config || {}
      provider_config['webhook_status'] = 'failed'
      provider_config['webhook_error'] = e.message
      provider_config['webhook_retry_needed'] = true
      provider_config['last_webhook_retry_at'] = Time.current.iso8601
      channel.update!(provider_config: provider_config)
      
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
    """Extract phone number from channel for webhook URL generation
    
    Args:
      channel: Channel::Whatsapp instance
      
    Returns:
      String: Phone number without 'pending:' prefix, nil if not available
    """
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
