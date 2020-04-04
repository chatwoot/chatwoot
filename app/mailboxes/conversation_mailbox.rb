class ConversationMailbox < ApplicationMailbox
  attr_accessor :conversation_uuid, :processed_mail

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+to+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  EMAIL_PART_PATTERN = /^reply\+to\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i.freeze

  before_processing :conversation_uuid_from_to_address,
                    :verify_decoded_params,
                    :find_conversation,
                    :process_mail

  def process
    create_message
    add_attachments_to_message
  end

  private

  def create_message
    @message = @conversation.messages.create(
      account_id: @conversation.account_id,
      contact_id: @conversation.contact_id,
      content: processed_mail.content,
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      source_id: processed_mail.message_id
    )
  end

  def add_attachments_to_message
    # add attachments
    # processed_mail.attachments
  end

  def conversation_uuid_from_to_address
    mail.to.each do |email|
      username = email.split('@')[0]
      match_result = username.match(EMAIL_PART_PATTERN)
      if match_result
        @conversation_uuid = match_result.captures
        return true
      end
    end
  end

  def verify_decoded_params
    raise 'Conversation uuid not found' if conversation_uuid.nil?
  end

  def find_conversation
    @conversation = Conversations.find_by(uuid: conversation_uuid)
    validate_resource @conversation
  end

  def validate_resource(resource)
    raise "#{resource.class.name} not found" if resource.nil?

    resource
  end

  def process_mail
    @processed_mail = EmailContentExtractor.new(mail)
  end
end
