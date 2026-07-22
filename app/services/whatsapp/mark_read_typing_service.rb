class Whatsapp::MarkReadTypingService
  THROTTLE_SECONDS = 12

  def initialize(conversation:, force: false)
    @conversation = conversation
    @force = force
  end

  def perform
    return false unless whatsapp_cloud_inbox?
    return false unless @force || throttle_allows?

    wamid = last_incoming_wamid
    return false if wamid.blank?

    channel.provider_service.mark_message_read_with_typing!(wamid)
  rescue StandardError => e
    Rails.logger.warn(
      "[WhatsApp] MarkReadTypingService conversation=#{@conversation.id} error=#{e.class}: #{e.message}"
    )
    false
  end

  private

  def whatsapp_cloud_inbox?
    inbox = @conversation.inbox
    inbox&.whatsapp? && inbox.channel.respond_to?(:provider) && inbox.channel.provider == 'whatsapp_cloud'
  end

  def channel
    @conversation.inbox.channel
  end

  def last_incoming_wamid
    @conversation.messages.incoming.where.not(source_id: [nil, '']).order(created_at: :desc).pick(:source_id)
  end

  def throttle_allows?
    key = "wa_mark_read_typing:#{@conversation.id}"
    # Redis SET NX EX — only one call per THROTTLE_SECONDS per conversation.
    Redis::Alfred.set(key, Time.now.utc.to_i, nx: true, ex: THROTTLE_SECONDS)
  end
end
