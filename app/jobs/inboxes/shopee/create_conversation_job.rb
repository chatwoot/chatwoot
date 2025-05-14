class Inboxes::Shopee::CreateConversationJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel_id, data)
    @channel_id = channel_id
    @data = data

    set_conversation
    fetch_messages
  end

  private

  attr_reader :channel_id
  attr_reader :data

  def current_channel
    @current_channel ||= Channel::Shopee.find(channel_id)
  end

  def contact_inbox
    @contact_inbox ||= ::ContactInboxWithContactBuilder.new(
      inbox: current_channel.inbox,
      source_id: data['conversation_id'],
      contact_attributes: {
        identifier: data['to_id'],
        name: data['to_name'],
        avatar_url: data['to_avatar'],
        custom_attributes: {
          platform: 'shopee',
        }
      }
    ).perform
  end

  def set_conversation
    if current_channel.inbox.lock_to_single_conversation
      @conversation = contact_inbox.conversations.last
    else
      @conversation = contact_inbox.conversations.where.not(status: :resolved).last
    end

    @conversation ||= current_channel.inbox.conversations.create!(
      account_id: current_channel.account_id,
      inbox_id: current_channel.inbox.id,
      contact_inbox_id: contact_inbox.id,
      contact_id: contact_inbox.contact_id,
    )
  end

  def fetch_messages
    response = Integrations::Shopee::Message.new(
      shop_id: current_channel.shop_id,
      access_token: current_channel.access_token
    ).list(data['conversation_id'])
    messages = response.dig('response', 'messages') || []
    messages.reverse.each do |message|
      incoming = message['to_shop_id'].to_i == current_channel.shop_id
      conversation_message = @conversation.messages.find_or_initialize_by(source_id: message['message_id'])
      conversation_message.assign_attributes(
        account_id: current_channel.account_id,
        inbox_id: current_channel.inbox.id,
        content: message.dig('content', 'text'),
        message_type: message_type(message, incoming: incoming),
        content_type: content_type(message),
        sender: incoming ? contact_inbox.contact : nil,
        content_attributes: content_attributes(message),
      )
      conversation_message.save! if conversation_message.changed?
      process_attachments(message, conversation_message)
    end
  end

  def content_attributes(message)
    {
      source_content: message['source_content'].to_h,
      original: message['content'].to_h,
      in_reply_to_external_id: message.dig('quoted_msg', 'message_id'),
    }
  end

  def message_type(message, incoming: false)
    case message['message_type']
    when 'notification'
      :activity
    else
      incoming ? :incoming : :outgoing
    end
  end

  def content_type(message)
    case message['message_type']
    when 'voucher', 'item_list', 'add_on_deal', 'order', 'product', 'item', 'faq_liveagent', 'crm_item_list'
      Message.content_types[:shopee_card]
    when 'sticker'
      Message.content_types[:sticker]
    else
      Message.content_types[:text]
    end
  end

  def process_attachments(message, conversation_message)
    # Attach image if present
    file_url = message.dig('content', 'url').presence
    file_url && conversation_message.attachments.find_or_create_by!(
      account_id: current_channel.account_id,
      external_url: file_url,
    )

    # Attach video if present
    video_url = message.dig('content', 'video_url').presence
    video_url && conversation_message.attachments.find_or_create_by!(
      account_id: current_channel.account_id,
      external_url: video_url,
      file_type: :video,
    )
  end

end
