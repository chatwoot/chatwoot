class Whatsapp::EmbeddedSignupService
  def initialize(account:, params:, inbox_id: nil)
    @account = account
    @code = params[:code]
    @business_id = params[:business_id]
    @waba_id = params[:waba_id]
    @phone_number_id = params[:phone_number_id]
    @inbox_id = inbox_id
  end

  def perform
    validate_parameters!

    access_token = exchange_code_for_token
    phone_info = fetch_phone_info(access_token)

    channel = create_or_reauthorize_channel(access_token, phone_info)
    # Enqueue webhook setup explicitly instead of relying on the after_commit callback because:
    # 1. Reauthorization flow updates an existing channel (not a create), so after_commit on: :create won't trigger
    # 2. The channel is marked with source: 'embedded_signup' to skip the after_commit callback
    # The job runs Meta's slow phone-registration/subscription calls off the request thread so they
    # can't trip Rack::Timeout and roll back the just-created channel. The provisioning health check
    # runs inside the job, after registration — and only for new channels, since a reauthorized
    # number in a pending state would otherwise trigger a spurious disconnect right after reauth.
    channel.enqueue_webhook_setup(run_health_check: @inbox_id.blank?)
    channel

  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Embedded signup failed: #{e.message}")
    raise e
  end

  private

  def exchange_code_for_token
    Whatsapp::TokenExchangeService.new(@code).perform
  end

  def fetch_phone_info(access_token)
    Whatsapp::PhoneInfoService.new(@waba_id, @phone_number_id, access_token).perform
  end

  def create_or_reauthorize_channel(access_token, phone_info)
    if @inbox_id.present?
      Whatsapp::ReauthorizationService.new(
        account: @account,
        inbox_id: @inbox_id,
        phone_number_id: @phone_number_id,
        waba_id: @waba_id
      ).perform(access_token, phone_info)
    else
      waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }
      Whatsapp::ChannelCreationService.new(@account, waba_info, phone_info, access_token).perform
    end
  end

  def validate_parameters!
    missing_params = []
    missing_params << 'code' if @code.blank?
    missing_params << 'business_id' if @business_id.blank?
    missing_params << 'waba_id' if @waba_id.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
