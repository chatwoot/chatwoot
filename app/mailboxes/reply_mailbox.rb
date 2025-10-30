class ReplyMailbox < ApplicationMailbox
  attr_accessor :conversation_uuid, :processed_mail

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  EMAIL_PART_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i

  before_processing :conversation_uuid_from_to_address,
                    :find_relative_conversation

  def process
    return if @conversation.blank?

    decorate_mail
    create_message
    add_attachments_to_message
  end

  private

  def find_relative_conversation
    if @conversation_uuid
      find_conversation_with_uuid
    elsif mail.in_reply_to.present? || mail.references.present?
      find_conversation_with_in_reply_to if mail.in_reply_to.present?
      # If still no conversation found and references exist, try references as fallback
      find_conversation_with_references if @conversation.blank? && mail.references.present?
    end
  end

  def conversation_uuid_from_to_address
    @mail = MailPresenter.new(mail)

    return if @mail.mail_receiver.blank?

    @mail.mail_receiver.each do |email|
      username = email.split('@')[0]
      match_result = username.match(ApplicationMailbox::REPLY_EMAIL_UUID_PATTERN)
      if match_result
        @conversation_uuid = match_result.captures
        break
      end
    end
    @conversation_uuid
  end

  # find conversation uuid from below pattern
  # reply+<conversation-uuid>@<mailer-domain.com>
  def find_conversation_with_uuid
    @conversation = Conversation.find_by(uuid: conversation_uuid)
    validate_resource @conversation
  end

  def find_conversation_by_uuid(match_result)
    @conversation_uuid = match_result.captures[0]

    find_conversation_with_uuid
  end

  def find_conversation_by_message_id(in_reply_to)
    @message = Message.find_by(source_id: in_reply_to)
    @conversation = @message.conversation if @message.present?
    @conversation_uuid = @conversation.uuid if @conversation.present?
  end

  # find conversation uuid from below pattern
  # <conversation/#{@conversation.uuid}/messages/#{@messages&.last&.id}@#{@account.inbound_email_domain}>
  def find_conversation_with_in_reply_to
    match_result = nil
    in_reply_to_addresses = mail.in_reply_to
    in_reply_to_addresses = [in_reply_to_addresses] if in_reply_to_addresses.is_a?(String)
    in_reply_to_addresses.each do |in_reply_to|
      match_result = in_reply_to.match(::ApplicationMailbox::CONVERSATION_MESSAGE_ID_PATTERN)
      break if match_result
    end
    find_by_in_reply_to_addresses(match_result, in_reply_to_addresses)
  end

  def find_by_in_reply_to_addresses(match_result, in_reply_to_addresses)
    find_conversation_by_uuid(match_result) if match_result
    find_conversation_by_message_id(in_reply_to_addresses) if @conversation.blank?
  end

  # Find conversation from References header as fallback
  # Extract conversation UUID from any reference that matches our patterns
  def find_conversation_with_references
    references_addresses = mail.references
    references_addresses = [references_addresses] if references_addresses.is_a?(String)

    references_addresses.each do |reference|
      conversation = find_conversation_from_reference(reference)
      next unless conversation && conversation_belongs_to_channel?(conversation)

      @conversation = conversation
      @conversation_uuid = conversation.uuid
      break
    end
  end

  def find_conversation_from_reference(reference)
    # Try message-specific pattern: conversation/{uuid}/messages/{id}@domain
    message_match = reference.match(::ApplicationMailbox::CONVERSATION_MESSAGE_ID_PATTERN)
    if message_match
      uuid = message_match.captures[0]
      conversation = Conversation.find_by(uuid: uuid)
      return conversation if conversation.present?
    end

    # Try conversation fallback pattern: account/{id}/conversation/{uuid}@domain
    fallback_match = reference.match(::ApplicationMailbox::CONVERSATION_FALLBACK_ID_PATTERN)
    if fallback_match
      uuid = fallback_match.captures[1]
      conversation = Conversation.find_by(uuid: uuid)
      return conversation if conversation.present?
    end

    # Try finding by message source_id
    message = Message.find_by(source_id: reference)
    message&.conversation
  end

  def conversation_belongs_to_channel?(conversation)
    return true unless conversation

    # Get the channel from the email's To/CC addresses
    channel = EmailChannelFinder.new(mail).perform
    return false unless channel

    # Check if the conversation's inbox matches the channel
    conversation.inbox.channel_id == channel.id
  end

  def validate_resource(resource)
    Rails.logger.error "[App::Mailboxes::ReplyMailbox] Email conversation with uuid: #{conversation_uuid} not found" if resource.nil?

    resource
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
