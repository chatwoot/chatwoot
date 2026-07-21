class Api::V1::Accounts::Whatsapp::AuthorizationsController < Api::V1::Accounts::BaseController
  before_action :ensure_embedded_signup_enabled
  # Reconfiguring/reauthorizing a live inbox swaps its credentials, so restrict it to admins.
  before_action :check_admin_authorization?, if: -> { params[:inbox_id].present? }
  before_action :fetch_and_validate_inbox, if: -> { params[:inbox_id].present? }

  # POST /api/v1/accounts/:account_id/whatsapp/authorization
  # Handles both initial authorization and reauthorization
  # If inbox_id is present in params, it performs reauthorization
  def create
    validate_embedded_signup_params!
    channel = process_embedded_signup
    render_success_response(channel.inbox)
  rescue CustomExceptions::Inbox::LimitExceeded => e
    render_error_response(e)
  rescue StandardError => e
    render_embedded_signup_error(e)
  end

  private

  def ensure_embedded_signup_enabled
    return unless ChatwootApp.chatwoot_cloud?
    return if Current.account.feature_enabled?('whatsapp_embedded_signup_inbox_creation')

    raise Pundit::NotAuthorizedError
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
    return if @inbox.channel.reauthorization_required? || can_reconfigure_channel?

    render json: {
      success: false,
      message: I18n.t('inbox.reauthorization.not_required')
    }, status: :unprocessable_entity
  end

  def can_reconfigure_channel?
    channel = @inbox.channel
    return false unless channel.provider == 'whatsapp_cloud'
    return true if ChatwootApp.chatwoot_cloud?
    return Current.account.feature_enabled?('whatsapp_reconfigure') if channel.provider_config['source'] == 'embedded_signup'

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

  def render_embedded_signup_error(error)
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
