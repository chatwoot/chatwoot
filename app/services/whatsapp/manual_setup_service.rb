class Whatsapp::ManualSetupService
  attr_reader :channel, :webhook_error

  def initialize(account:, waba_id:, phone_number_id:, access_token:, inbox_name: nil)
    @account = account
    @waba_id = waba_id
    @phone_number_id = phone_number_id
    @access_token = access_token
    @inbox_name = inbox_name
  end

  def perform
    preview = validate_setup
    create_channel_and_inbox(preview)
    setup_webhook
    self
  end

  def webhook_setup?
    webhook_error.blank?
  end

  private

  def validate_setup
    Whatsapp::ManualSetupValidationService.new(
      waba_id: @waba_id,
      phone_number_id: @phone_number_id,
      access_token: @access_token
    ).perform
  end

  def create_channel_and_inbox(preview)
    ActiveRecord::Base.transaction do
      @channel = @account.whatsapp_channels.create!(
        phone_number: preview[:display_phone_number],
        provider: 'whatsapp_cloud',
        provider_config: {
          api_key: @access_token,
          phone_number_id: preview[:phone_number_id],
          business_account_id: preview[:waba_id],
          source: 'manual_setup_v2'
        }
      )
      @account.inboxes.create!(
        name: @inbox_name.to_s.strip.presence || preview[:suggested_inbox_name],
        channel: @channel
      )
    end
  end

  def setup_webhook
    webhook_setup = Whatsapp::WebhookSetupService.new(@channel, @waba_id, @access_token)
    webhook_setup.perform
    raise webhook_setup.registration_error if webhook_setup.registration_error
  rescue StandardError => e
    @webhook_error = e.message
  end
end
