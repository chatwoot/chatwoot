module Tiktok::MessagingHelpers
  private

  def create_contact_inbox(channel, tt_conversation_id, from, from_id)
    ::ContactInboxWithContactBuilder.new(
      source_id: tt_conversation_id,
      inbox: channel.inbox,
      contact_attributes: contact_attributes(from, from_id)
    ).perform
  end

  def contact_attributes(from, from_id)
    {
      name: from,
      additional_attributes: contact_additional_attributes(from, from_id)
    }
  end

  def contact_additional_attributes(from, from_id)
    {
      # TODO: Remove this once we show the social_tiktok_user_name in the UI instead of the username
      username: from,
      social_profiles: { tiktok: from },
      social_tiktok_user_id: from_id,
      social_tiktok_user_name: from
    }
  end

  def find_conversation(channel, tt_conversation_id)
    channel.inbox.contact_inboxes.find_by(source_id: tt_conversation_id)&.conversations&.first
  end

  def create_conversation(channel, contact_inbox, tt_conversation_id)
    ::Conversation.create!(conversation_params(channel, contact_inbox, tt_conversation_id))
  end

  def conversation_params(channel, contact_inbox, tt_conversation_id)
    {
      account_id: channel.inbox.account_id,
      inbox_id: channel.inbox.id,
      contact_id: contact_inbox.contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: conversation_additional_attributes(tt_conversation_id)
    }
  end

  def conversation_additional_attributes(tt_conversation_id)
    {
      conversation_id: tt_conversation_id
    }
  end

  def find_message(tt_conversation_id, tt_message_id)
    message = Message.find_by(source_id: tt_message_id)
    message_conversation_id = message&.conversation&.[](:additional_attributes)&.[]('conversation_id')
    return if message_conversation_id != tt_conversation_id

    message
  end

  def fetch_attachment(channel, tt_conversation_id, tt_message_id, tt_image_media_id)
    file_download_url = tiktok_client(channel).file_download_url(tt_conversation_id, tt_message_id, tt_image_media_id)
    Down.download(file_download_url, headers: { 'x-user' => channel.validated_access_token })
  end

  def tiktok_client(channel)
    Tiktok::Client.new(business_id: channel.business_id,  access_token: channel.validated_access_token)
  end
end
