class WhatsappUnofficial::CreateWhatsappUnofficialInboxService
  def self.call(account_id:, phone_number:, inbox_name:, token:)
    channel = Channel::WhatsappUnofficial.create!(
      account_id: account_id,
      phone_number: phone_number,
      webhook_url: 'TEMP'
    )

    inbox = Inbox.new(
      account_id: account_id,
      name: inbox_name,
      channel: channel,
      channel_type: 'Channel::WhatsappUnofficial'
    )

    Inbox.transaction do
      inbox.save!(validate: false)
    end

    webhook_url = build_webhook_url(account_id, inbox.id, token)

    channel.update!(webhook_url: webhook_url)

    { inbox: inbox, webhook_url: webhook_url }
  end

  def self.build_webhook_url(account_id, inbox_id, token)
    base_url = ENV.fetch('WA_UNOFFICIAL_WEBHOOK_BASE_URL', nil)
    code = ENV.fetch('WA_UNOFFICIAL_WEBHOOK_SECRET_CODE', nil)
    incoming_message = ENV.fetch('WA_UNOFFICIAL_WEBHOOK_INCOMING_MESSAGE', nil)

    query = {
      code: code,
      incoming_message: incoming_message,
      account_id: account_id,
      inbox_id: inbox_id,
      token: token
    }.to_query

    "#{base_url}?#{query}"
  end
end
