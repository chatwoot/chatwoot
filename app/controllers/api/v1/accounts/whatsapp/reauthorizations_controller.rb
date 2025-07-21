class Api::V1::Accounts::Whatsapp::ReauthorizationsController < Api::V1::Accounts::BaseController
  before_action :authorize_request
  before_action :fetch_inbox
  before_action :check_reauthorization_required
  before_action :validate_whatsapp_channel

  def update
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
  end

  private

  def authorize_request
    authorize Current.account, :update?
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  rescue ActiveRecord::RecordNotFound
    render_not_found_error('Inbox not found')
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

  def reauthorization_service
    @reauthorization_service ||= Whatsapp::ReauthorizationService.new(
      inbox: @inbox,
      code: permitted_params[:code],
      business_id: permitted_params[:business_id],
      waba_id: permitted_params[:waba_id],
      phone_number_id: permitted_params[:phone_number_id]
    )
  end

  def permitted_params
    params.permit(:code, :business_id, :waba_id, :phone_number_id)
  end
end
