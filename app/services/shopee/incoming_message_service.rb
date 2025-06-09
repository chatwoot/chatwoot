# ref : https://developers.line.biz/en/docs/messaging-api/receiving-messages/#webhook-event-types
# https://developers.line.biz/en/reference/messaging-api/#message-event

class Shopee::IncomingMessageService
  pattr_initialize [:inbox!, :params!]
  VALID_MESSAGE_TYPES = %w[text sticker voucher item_list add_on_deal order product item faq_liveagent crm_item_list].freeze

  delegate :channel, to: :inbox

  def perform
    load_attributes
    return if invalid_payload?

    set_contact
    set_conversation
    update_or_create_message
    process_attachments if message.attachments.empty?
  end

  private

  attr_reader :payload, :message_id, :conversation_id, :message_content, :message

  def load_attributes
    @payload = params.dig(:data, :content).presence || {}
    @message_id = params.dig(:data, :content, :message_id)
    @conversation_id = params.dig(:data, :content, :conversation_id)
    @message_content = params.dig(:data, :content, :content, :text).presence
  end

  def invalid_payload?
    message_id.blank? ||
      conversation_id.blank? ||
      VALID_MESSAGE_TYPES.exclude?(payload[:message_type])
  end

  def set_contact
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: conversation_id,
      contact_attributes: contact_attributes
    ).perform
    @contact = @contact_inbox.contact
    sync_contact_avatar
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.unresolved.last
    @conversation ||= inbox.conversations.create!(
      contact_id: @contact.id,
      account_id: inbox.account_id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def update_or_create_message
    @message = @conversation.messages.find_or_initialize_by(source_id: message_id)
    @message.update(
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      status: :delivered,
      message_type: :incoming,
      sender: @contact,
      content_type: content_type,
      content_attributes: content_attributes
    )
  end

  def process_attachments
    # Attach image if present
    file_url = payload.dig(:content, :url).presence
    file_url && message.attachments.find_or_create_by!(
      account_id: channel.account_id,
      external_url: file_url
    )

    # Attach video if present
    video_url = payload.dig(:content, :video_url).presence
    video_url && message.attachments.find_or_create_by!(
      account_id: channel.account_id,
      external_url: video_url,
      file_type: :video
    )
  end

  def sync_contact_avatar
    return if @contact.avatar.attached?

    shopee_conversation ||= Integrations::Shopee::Conversation.new(
      shop_id: channel.shop_id,
      access_token: channel.access_token
    ).detail(conversation_id)
    avatar_url = shopee_conversation.dig('response', 'to_avatar')
    ::Avatar::AvatarFromUrlJob.set(wait: 10.seconds).perform_later(@contact, avatar_url) if avatar_url
  rescue StandardError => e
    Rails.logger.error("Failed to sync contact avatar for Shopee conversation #{conversation_id}: #{e.message}")
  end

  def content_type
    case payload[:message_type]
    when 'voucher', 'item_list', 'add_on_deal', 'order', 'product', 'item', 'faq_liveagent', 'crm_item_list'
      Message.content_types[:shopee_card]
    when 'sticker'
      Message.content_types[:sticker]
    else
      Message.content_types[:text]
    end
  end

  def contact_attributes
    {
      identifier: payload[:from_id],
      name: payload[:from_user_name],
      custom_attributes: {
        platform: :shopee
      }
    }
  end

  def content_attributes
    {
      original: payload[:content],
      in_reply_to_external_id: payload.dig(:quoted_msg, :message_id)
    }
  end
end
