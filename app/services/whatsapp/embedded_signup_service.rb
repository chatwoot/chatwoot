class Whatsapp::EmbeddedSignupService
  include Rails.application.routes.url_helpers
  include Whatsapp::ApiService
  include Whatsapp::TokenValidator

  def initialize(params)
    @account = params[:account]
    @code = params[:code]
    @business_id = params[:business_id]
    @waba_id = params[:waba_id]
    @phone_number_id = params[:phone_number_id]
    @inbox_id = params[:inbox_id]
  end

  def perform
    # Validate required parameters
    unless @code.present? && @business_id.present? && @waba_id.present? && @phone_number_id.present?
      raise ArgumentError, 'Code, business_id, waba_id, and phone_number_id are all required'
    end

    GlobalConfig.clear_cache
    # Exchange code for user access token
    access_token = exchange_code_for_token

    # Use the provided business info directly (more efficient)
    phone_info = fetch_phone_info_via_waba(@waba_id, @phone_number_id, access_token)

    # Validate that the token has access to the provided WABA (security check)
    validate_token_waba_access(access_token, @waba_id)

    waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }

    create_or_update_channel(waba_info, phone_info, access_token)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Signup failed: #{e.message}")
    raise e
  end

  def perform_reauthorization
    validate_reauthorization_params!
    channel = find_and_validate_channel

    GlobalConfig.clear_cache
    access_token = exchange_code_for_token
    phone_info = fetch_phone_info_via_waba(@waba_id, @phone_number_id, access_token)
    validate_token_waba_access(access_token, @waba_id)

    update_channel_for_reauthorization(channel, phone_info, access_token)
    register_phone_number(phone_info[:phone_number_id], access_token)
    override_waba_webhook(@waba_id, channel, access_token)

    channel
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Reauthorization failed: #{e.message}")
    raise e
  end

  private

  def validate_reauthorization_params!
    return if @code.present? && @business_id.present? && @waba_id.present? && @phone_number_id.present? && @inbox_id.present?

    raise ArgumentError, 'Code, business_id, waba_id, phone_number_id, and inbox_id are all required for reauthorization'
  end

  def find_and_validate_channel
    inbox = @account.inboxes.find_by(id: @inbox_id)
    raise ActiveRecord::RecordNotFound, 'Inbox not found' unless inbox
    raise ArgumentError, 'Inbox is not a WhatsApp channel' unless inbox.channel_type == 'Channel::Whatsapp'

    channel = inbox.channel
    raise ArgumentError, 'Channel is not WhatsApp Cloud provider' unless channel.provider == 'whatsapp_cloud'

    channel
  end

  def create_or_update_channel(waba_info, phone_info, access_token)
    existing_channel = find_existing_channel(phone_info[:phone_number])
    channel_attributes = build_channel_attributes(waba_info, phone_info, access_token)

    if existing_channel
      Rails.logger.error("Channel already exists: #{existing_channel.inspect}")
      raise "Channel already exists: #{existing_channel.phone_number}"
    else
      channel = create_new_channel(channel_attributes, phone_info)
      register_phone_number(phone_info[:phone_number_id], access_token)
      override_waba_webhook(waba_info[:waba_id], channel, access_token)
      channel
    end
  end

  def find_existing_channel(phone_number)
    Channel::Whatsapp.find_by(account: @account, phone_number: phone_number)
  end

  def build_channel_attributes(waba_info, phone_info, access_token)
    {
      phone_number: phone_info[:phone_number],
      provider: 'whatsapp_cloud',
      provider_config: {
        api_key: access_token,
        phone_number_id: phone_info[:phone_number_id],
        business_account_id: waba_info[:waba_id],
        source: 'embedded_signup'
      }
    }
  end

  def create_new_channel(attributes, phone_info)
    channel = Channel::Whatsapp.create!(account: @account, **attributes)
    create_inbox_for_channel(channel, phone_info)
    channel.reload
    channel
  end

  def create_inbox_for_channel(channel, phone_info)
    Inbox.create!(
      account: @account,
      name: "#{phone_info[:business_name]} WhatsApp",
      channel: channel
    )
  end

  def update_channel_for_reauthorization(channel, phone_info, access_token)
    # Update channel with new access token and configuration
    channel.update!(
      provider_config: channel.provider_config.merge(
        'api_key' => access_token,
        'phone_number_id' => phone_info[:phone_number_id],
        'business_account_id' => @waba_id,
        'reauthorized_at' => Time.current.iso8601
      )
    )
  end
end
