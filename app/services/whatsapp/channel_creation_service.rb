class Whatsapp::ChannelCreationService
  def initialize(account, waba_info, phone_info, access_token)
    @account = account
    @waba_info = waba_info
    @phone_info = phone_info
    @access_token = access_token
  end

  def perform
    validate_parameters!

    existing_channel = find_existing_channel
    raise "Channel already exists: #{existing_channel.phone_number}" if existing_channel

    create_channel_with_inbox
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Account is required' if @account.blank?
    raise ArgumentError, 'WABA info is required' if @waba_info.blank?
    raise ArgumentError, 'Phone info is required' if @phone_info.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
  end

  def find_existing_channel
    Channel::Whatsapp.find_by(
      account: @account,
      phone_number: @phone_info[:phone_number]
    )
  end

  def create_channel_with_inbox
    ActiveRecord::Base.transaction do
      channel = build_channel
      create_inbox(channel)
      channel
    end
  end

  def build_channel
    Channel::Whatsapp.build(
      account: @account,
      phone_number: @phone_info[:phone_number],
      provider: 'whatsapp_cloud',
      provider_config: build_provider_config
    )
  end

  def build_provider_config
    {
      api_key: @access_token,
      phone_number_id: @phone_info[:phone_number_id],
      business_account_id: @waba_info[:waba_id],
      source: 'embedded_signup'
    }
  end

  def create_inbox(channel)
    inbox_name = build_inbox_name

    Inbox.create!(
      account: @account,
      name: inbox_name,
      channel: channel
    )
  end

  def build_inbox_name
    business_name = @phone_info[:business_name] || @waba_info[:business_name]
    "#{business_name} WhatsApp"
  end
end
