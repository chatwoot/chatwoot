class ReplyMailbox < ApplicationMailbox
  attr_accessor :conversation_uuid, :processed_mail

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  EMAIL_PART_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i

  before_processing :conversation_uuid_from_to_address,
                    :find_relative_conversation,
                    :verify_decoded_params,
                    :decorate_mail

  def process
    create_message
    add_attachments_to_message
  end

  private

  def find_relative_conversation
    if @conversation_uuid
      find_conversation_with_uuid
    elsif mail['In-Reply-To'].try(:value).present?
      find_conversation_with_in_reply_to
    end
  end

  def conversation_uuid_from_to_address
    mail.to.each do |email|
      username = email.split('@')[0]
      match_result = username.match(ApplicationMailbox::REPLY_EMAIL_UUID_PATTERN)
      if match_result
        @conversation_uuid = match_result.captures
        break
      end
    end
    @conversation_uuid
  end

  def verify_decoded_params
    raise 'Conversation uuid not found' if conversation_uuid.nil?
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
    in_reply_to = mail['In-Reply-To'].try(:value)
    match_result = in_reply_to.match(ApplicationMailbox::CONVERSATION_MESSAGE_ID_PATTERN) if in_reply_to.present?

    if match_result
      find_conversation_by_uuid(match_result)
    else
      find_conversation_by_message_id(in_reply_to)
    end
  end

  def validate_resource(resource)
    raise "#{resource.class.name} not found" if resource.nil?

    resource
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
