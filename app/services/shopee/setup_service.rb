class Shopee::SetupService
  pattr_initialize [:channel_id]

  def perform
    conversations.each do |conversation|
      next if conversation['conversation_id'].blank?

      job_attrs = conversation.slice('conversation_id', 'to_id', 'to_name', 'to_avatar')
      ActiveRecord::Base.transaction do
        create_conversation(job_attrs)
        Inboxes::Shopee::CreateConversationJob.perform_later(channel_id, job_attrs)
      end
    end
  end

  private

  def create_conversation(data)
  end

  def inbox
    @inbox ||= channel.inbox || raise('Channel inbox not found')
  end

  def channel
    @channel ||= Channel::Shopee.find(channel_id)
  end

  def conversations
    return @conversations if defined?(@conversations)

    list ||= Integrations::Shopee::Conversation.new(
      shop_id: channel.shop_id,
      access_token: channel.access_token
    ).list

    @conversations = list.dig('response', 'conversations') || []
  end
end
