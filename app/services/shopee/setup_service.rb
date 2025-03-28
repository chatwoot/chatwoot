class Shopee::SetupService
  pattr_initialize [:channel_id]

  def perform; end

  private

  def inbox
    @inbox ||= channel.inbox || raise('Channel inbox not found')
  end

  def channel
    @channel ||= Channel::Shopee.find(channel_id)
  end

  def conversations
    @conversations ||= Integrations::Shopee::Conversation.new(
      shop_id: channel.shop_id,
      access_token: channel.access_token
    ).list
  end
end
