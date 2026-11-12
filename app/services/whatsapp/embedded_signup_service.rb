class Whatsapp::EmbeddedSignupService
  def initialize(account:, params:, inbox_id: nil)
    @account = account
    @code = params[:code]
    @waba_id = params[:waba_id]
    @phone_number_id = params[:phone_number_id]
    @inbox_id = inbox_id
    @is_coexistence = ActiveModel::Type::Boolean.new.cast(params[:is_coexistence])
  end

  # Only the steps the inbox depends on run in the request: the auth code expires 30 seconds after Meta issues it.
  # Registration and webhook setup run in Channels::Whatsapp::EmbeddedSignupSetupJob.
  def perform
    validate_parameters!

    access_token = exchange_code_for_token
    phone_info = fetch_phone_info(access_token)
    inbox_id = @inbox_id.presence || existing_inbox_id(phone_info[:phone_number])

    channel = create_or_reauthorize_channel(inbox_id, access_token, phone_info)
    # Skip the health check on reauth (avoids false disconnect emails) and on coexistence signups
    # (Meta's health data can lag several minutes behind a fresh FINISH event).
    Channels::Whatsapp::EmbeddedSignupSetupJob.perform_later(
      channel, is_coexistence: @is_coexistence, check_health: inbox_id.blank? && !@is_coexistence
    )
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
    Whatsapp::PhoneInfoService.new(
      @waba_id, @phone_number_id, access_token, expected_phone_number: reauthorizing_channel&.phone_number
    ).perform
  end

  # When phone_number_id is omitted (coexistence completions can leave it blank), this lets
  # PhoneInfoService match the WABA number against the channel being reauthorized instead of
  # arbitrarily taking the first number, which would misidentify a WABA with multiple numbers.
  def reauthorizing_channel
    return nil if @inbox_id.blank?

    @reauthorizing_channel ||= @account.inboxes.find(@inbox_id).channel
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Customers re-run signup for a number this account already has, usually after a signup that timed out or after
  # Meta removed our access. Reconnecting that inbox keeps its history; creating a second one is refused anyway.
  # Manually connected inboxes run on the customer's own Meta app, so signup must not silently take them over.
  def existing_inbox_id(phone_number)
    channel = @account.whatsapp_channels.find_by(phone_number: phone_number, provider: 'whatsapp_cloud')
    return if channel.blank? || channel.provider_config['source'] != 'embedded_signup'

    channel.inbox&.id
  end

  def create_or_reauthorize_channel(inbox_id, access_token, phone_info)
    if inbox_id.present?
      Whatsapp::ReauthorizationService.new(
        account: @account,
        inbox_id: inbox_id,
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
    missing_params << 'waba_id' if @waba_id.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
