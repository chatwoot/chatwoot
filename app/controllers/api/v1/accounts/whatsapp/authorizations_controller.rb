class Api::V1::Accounts::Whatsapp::AuthorizationsController < Api::V1::Accounts::BaseController
  before_action :validate_feature_enabled!, only: [:create]
  before_action :authorize_request, only: [:update]
  before_action :fetch_and_validate_inbox, only: [:update]
  before_action :check_reauthorization_required, only: [:update]

  # POST /api/v1/accounts/:account_id/whatsapp/authorization
  # Handles the embedded signup callback data from the Facebook SDK for initial authorization
  def create
    validate_embedded_signup_params!
    channel = process_embedded_signup
    render_success_response(channel.inbox)
  rescue StandardError => e
    render_error_response(e)
  end

  # PUT /api/v1/accounts/:account_id/whatsapp/authorization
  # Handles reauthorization for existing WhatsApp channels
  # Requires inbox_id in request body params
  def update
    validate_embedded_signup_params!
    service_response = reauthorization_service.perform

    if service_response[:success]
      render json: {
        success: true,
        inbox_id: @inbox.id,
        message: I18n.t('inbox.reauthorization.success')
      }
    else
      render json: {
        success: false,
        message: service_response[:message]
      }, status: :bad_request
    end
  rescue StandardError => e
    render_error_response(e)
  end

  private

  def process_embedded_signup
    service = Whatsapp::EmbeddedSignupService.new(
      account: Current.account,
      code: authorization_params[:code],
      business_id: authorization_params[:business_id],
      waba_id: authorization_params[:waba_id],
      phone_number_id: authorization_params[:phone_number_id]
    )
    service.perform
  end

  def reauthorization_service
    @reauthorization_service ||= Whatsapp::ReauthorizationService.new(
      inbox: @inbox,
      code: authorization_params[:code],
      business_id: authorization_params[:business_id],
      waba_id: authorization_params[:waba_id],
      phone_number_id: authorization_params[:phone_number_id]
    )
  end

  def fetch_and_validate_inbox
    @inbox = Current.account.inboxes.find(authorization_params[:inbox_id])
    validate_whatsapp_channel
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Inbox not found'
    }, status: :not_found
  end

  def check_reauthorization_required
    # Allow reauthorization if:
    # 1. The channel needs reauthorization (tokens expired)
    # 2. It's a manual setup that can be upgraded to embedded signup
    return if @inbox.channel.reauthorization_required? || can_upgrade_to_embedded_signup?

    render json: {
      success: false,
      message: I18n.t('inbox.reauthorization.not_required')
    }, status: :unprocessable_entity
  end

  def can_upgrade_to_embedded_signup?
    channel = @inbox.channel
    return false unless channel.provider == 'whatsapp_cloud'

    GlobalConfigService.load('WHATSAPP_APP_ID', '').present?
  end

  def validate_whatsapp_channel
    return if @inbox.channel_type == 'Channel::Whatsapp'

    render json: {
      success: false,
      message: I18n.t('inbox.reauthorization.invalid_channel')
    }, status: :unprocessable_entity
  end

  def render_success_response(inbox)
    render json: {
      success: true,
      id: inbox.id,
      name: inbox.name,
      channel_type: 'whatsapp'
    }
  end

  def render_error_response(error)
    Rails.logger.error "[WHATSAPP AUTHORIZATION] Error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render json: {
      success: false,
      message: error.message
    }, status: :unprocessable_entity
  end

  def validate_feature_enabled!
    return if Current.account.feature_whatsapp_embedded_signup?

    render json: {
      success: false,
      message: 'WhatsApp embedded signup is not enabled for this account'
    }, status: :forbidden
  end

  def validate_embedded_signup_params!
    missing_params = []
    missing_params << 'code' if authorization_params[:code].blank?
    missing_params << 'business_id' if authorization_params[:business_id].blank?
    missing_params << 'waba_id' if authorization_params[:waba_id].blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end

  def authorize_request
    authorize Current.account, :update?
  end

  def authorization_params
    params.permit(:code, :business_id, :waba_id, :phone_number_id, :inbox_id)
  end
end
