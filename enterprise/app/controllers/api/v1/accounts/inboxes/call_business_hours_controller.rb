class Api::V1::Accounts::Inboxes::CallBusinessHoursController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_settings

  rescue_from CustomExceptions::InvalidAnnouncementAudio do |error|
    render json: { error: error.message }, status: error.http_status
  end

  def update
    Voice::BusinessHoursSettingsService.new(
      inbox: @inbox, enabled: params[:business_hours_calls_enabled], message: @message
    ).perform
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    return if @inbox.twilio? && @inbox.channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.call_business_hours.unsupported_inbox'))
  end

  def validate_settings
    enabled = params[:business_hours_calls_enabled]
    message = params[:out_of_hours_call_message]
    unless [true, false].include?(enabled) && message.is_a?(String)
      return render_could_not_create_error(I18n.t('inbox.call_business_hours.invalid_settings'))
    end

    @message = message.strip
    return render_could_not_create_error(I18n.t('inbox.call_business_hours.message_required')) if enabled && @message.empty?
    return unless @message.length > Voice::BusinessHoursSettingsService::MESSAGE_MAX_LENGTH

    render_could_not_create_error(I18n.t('inbox.call_business_hours.message_too_long'))
  end
end
