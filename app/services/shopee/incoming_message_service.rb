# ref : https://developers.line.biz/en/docs/messaging-api/receiving-messages/#webhook-event-types
# https://developers.line.biz/en/reference/messaging-api/#message-event

class Shopee::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    load_attributes

    return if invalid_payload?
    return unless event_type_message?

    set_contact
    set_conversation
    update_or_create_message
  end

  private

  attr_reader :payload, :message_id, :conversation_id, :message_content

  def load_attributes
    @payload = params.dig(:data, :content).presence || {}
    @message_id = params.dig(:data, :content, :message_id)
    @conversation_id = params.dig(:data, :content, :conversation_id)
    @message_content = params.dig(:data, :content, :content, :text).presence
  end

  def invalid_payload?
    message_id.blank? || conversation_id.blank?
  end

  def event_type_message?
    payload[:message_type] == 'text'
  end

  def set_contact
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: conversation_id,
      contact_attributes: contact_attributes
    ).perform
    @contact = @contact_inbox.contact
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
    @conversation.messages.find_or_initialize_by(source_id: message_id)
                 .update(
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
      # avatar_url: data['to_avatar'],
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
