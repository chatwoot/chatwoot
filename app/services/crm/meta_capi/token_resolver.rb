# Resolves the WhatsApp Cloud credentials used to post CAPI-BM events for a card.
#
# CAPI-BM only works against Meta's WhatsApp Cloud (not 360dialog), so we resolve the
# card's own conversation/inbox channel first and fall back to the account's first
# WhatsApp Cloud channel. Returns nil when no usable channel/token/WABA exists.
class Crm::MetaCapi::TokenResolver
  CLOUD_PROVIDER = 'whatsapp_cloud'.freeze

  Credentials = Struct.new(:access_token, :waba_id, keyword_init: true)

  def self.resolve(card)
    new(card).resolve
  end

  def initialize(card)
    @card = card
  end

  def resolve
    channel = whatsapp_channel
    return if channel.blank?

    access_token = channel.provider_config['api_key']
    waba_id = channel.waba_id
    return if access_token.blank? || waba_id.blank?

    Credentials.new(access_token: access_token, waba_id: waba_id)
  end

  private

  def whatsapp_channel
    linked_channel || @card.account.whatsapp_channels.find { |channel| cloud?(channel) }
  end

  def linked_channel
    inbox = @card.primary_conversation&.inbox || @card.inbox
    channel = inbox&.channel
    channel if channel.is_a?(Channel::Whatsapp) && cloud?(channel)
  end

  def cloud?(channel)
    channel.provider == CLOUD_PROVIDER
  end
end
