class WhatsappUnofficial::CreateWhatsappUnofficialInboxService
  def initialize(account_id:, phone_number:, inbox_name:)
    @account_id = account_id
    @phone_number = phone_number
    @inbox_name = inbox_name
  end

  def perform
    @channel = create_channel
    inbox = create_inbox

    Inbox.transaction do
      inbox.save!(validate: false)
    end

    { inbox: inbox, webhook_url: @channel.webhook_url }
  end

  private

  def create_channel
    channel = Channel::WhatsappUnofficial.create!(
      account_id: @account_id,
      phone_number: @phone_number,
      webhook_url: 'https://dev-omnichannel.radyalabs.com/fonnte/callback'
    )
    channel.set_token
    channel
  end

  def create_inbox
    Inbox.create!(
      account_id: @account_id,
      name: @inbox_name,
      channel: @channel,
      channel_type: 'Channel::WhatsappUnofficial'
    )
  end
end
