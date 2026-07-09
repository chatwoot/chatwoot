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
    # Webhook setup + health check hit the Meta Graph API and can be slow enough to blow past the
    # web request timeout (the channel is already persisted by this point, so the inbox exists even
    # when the request 500s). Run them in a background job so the controller can return immediately.
    # We enqueue explicitly instead of relying on the after_commit callback because the channel is
    # marked source: 'embedded_signup' (which skips that callback) and reauthorization updates an
    # existing channel rather than creating one. Skip the health check during reauthorization —
    # phone numbers in a pending provisioning state would otherwise trigger a false disconnect email.
    Whatsapp::SetupWebhooksJob.perform_later(channel, run_health_check: @inbox_id.blank?)
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
        business_id: @business_id
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
