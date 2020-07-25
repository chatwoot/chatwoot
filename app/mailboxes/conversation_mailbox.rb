class ConversationMailbox < ApplicationMailbox
  attr_accessor :conversation_uuid, :processed_mail

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  EMAIL_PART_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i.freeze

  before_processing :conversation_uuid_from_to_address,
                    :verify_decoded_params,
                    :find_conversation,
                    :decorate_mail

  def process
    create_message
    add_attachments_to_message
  end

  private

  def create_message
    @message = @conversation.messages.create(
      account_id: @conversation.account_id,
      sender: @conversation.contact,
      content: processed_mail.text_content[:reply],
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      content_type: 'incoming_email',
      source_id: processed_mail.message_id,
      content_attributes: {
        email: processed_mail.serialized_data
      }
    )
  end

  def add_attachments_to_message
    processed_mail.attachments.each do |mail_attachment|
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: 'file'
      )
      attachment.file.attach(mail_attachment[:blob])
    end
    @message.save!
  end

  def conversation_uuid_from_to_address
    mail.to.each do |email|
      username = email.split('@')[0]
      match_result = username.match(ApplicationMailbox::REPLY_EMAIL_USERNAME_PATTERN)
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

  def find_conversation
    @conversation = Conversation.find_by(uuid: conversation_uuid)
    validate_resource @conversation
  end

  def validate_resource(resource)
    raise "#{resource.class.name} not found" if resource.nil?

    resource
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
