class Api::V1::Accounts::Whatsapp::ReauthorizationsController < Api::V1::Accounts::BaseController
  before_action :authorize_request
  before_action :fetch_inbox
  before_action :check_reauthorization_required
  before_action :validate_whatsapp_channel

  def create
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
      }, status: :unprocessable_entity
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
    return if @inbox.channel.reauthorization_required?

    render json: {
      success: false,
      message: I18n.t('inbox.reauthorization.not_required')
    }, status: :unprocessable_entity
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
