class Tiktok::MessageService
  include Tiktok::MessagingHelpers

  pattr_initialize [:channel!, :content!]

  def perform
    if outgoing_message?
      # Skip processing echo messages
      message = find_message(tt_conversation_id, tt_message_id)
      return if message.present?
    end

    create_message
  end

  private

  def contact_inbox
    @contact_inbox ||= create_contact_inbox(channel, tt_conversation_id, incoming_message? ? from : to, incoming_message? ? from_id : to_id)
  end

  def contact
    contact_inbox.contact
  end

  def conversation
    @conversation ||= contact_inbox.conversations.first || create_conversation(channel, contact_inbox, tt_conversation_id)
  end

  def create_message
    message = conversation.messages.build(
      content: message_content,
      account_id: channel.inbox.account_id,
      inbox_id: channel.inbox.id,
      message_type: incoming_message? ? :incoming : :outgoing,
      content_attributes: message_content_attributes,
      source_id: tt_message_id,
      created_at: tt_message_time,
      updated_at: tt_message_time
    )

    message.sender = contact_inbox.contact if incoming_message?
    message.status = :delivered if outgoing_message?

    create_message_attachments(message)
    message.save!
  end

  def message_content
    return unless text_message?

    tt_text_body
  end

  def create_message_attachments(message)
    create_image_message_attachment(message) if image_message?
    create_share_post_message_attachment(message) if share_post_message?
  end

  def create_image_message_attachment(message)
    return unless image_message?

    attachment_file = fetch_attachment(channel, tt_conversation_id, tt_message_id, tt_image_media_id)

    message.attachments.new(
      account_id: message.account_id,
      file_type: :image,
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def create_share_post_message_attachment(message)
    return unless share_post_message?

    message.attachments.new(
      account_id: message.account_id,
      file_type: :embed,
      external_url: tt_share_post_embed_url
    )
  end

  def supported_message?
    text_message? || image_message? || share_post_message?
  end

  def message_content_attributes
    attributes = {}
    attributes[:in_reply_to_external_id] = tt_referenced_message_id if tt_referenced_message_id
    attributes[:is_unsupported] = true unless supported_message?
    attributes
  end

  def text_message?
    tt_message_type == 'text'
  end

  def image_message?
    tt_message_type == 'image'
  end

  def sticker_message?
    tt_message_type == 'sticker'
  end

  def share_post_message?
    tt_message_type == 'share_post'
  end

  def tt_text_body
    return unless text_message?

    content[:text][:body]
  end

  def tt_image_media_id
    return unless image_message?

    content[:image][:media_id]
  end

  def tt_share_post_embed_url
    return unless share_post_message?

    content[:share_post][:embed_url]
  end

  def tt_referenced_message_id
    content[:referenced_message_info]&.[](:referenced_message_id)
  end

  def tt_message_type
    content[:type]
  end

  def tt_message_id
    content[:message_id]
  end

  def tt_message_time
    Time.zone.at(content[:timestamp] / 1000).utc
  end

  def tt_conversation_id
    content[:conversation_id]
  end

  def from
    content[:from]
  end

  def from_id
    content[:from_user][:id]
  end

  def to
    content[:to]
  end

  def to_id
    content[:to_user][:id]
  end

  def incoming_message?
    channel.business_id == to_id
  end

  def outgoing_message?
    !incoming_message?
  end
end
