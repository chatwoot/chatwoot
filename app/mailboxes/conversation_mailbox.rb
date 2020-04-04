class ConversationMailbox < ApplicationMailbox
  attr_accessor :account_id, :inbox_id, :conversation_id, :processed_email
  EMAIL_PART_PATTERN = /(\d+)\+(\d+)\+(\d+)/i.freeze

  before_processing :pre_process_to_address,
                    :verify_decoded_params,
                    :find_account,
                    :find_inbox,
                    :find_conversation,
                    :process_email

  def process
    @conversation.messages.create(
      account_id: @conversation.account_id,
      contact_id: @conversation.contact_id,
      content: processed_email.content,
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      source_id: processed_email.message_id
    )
  end

  private

  def pre_process_to_address
    email_first_part = mail.to[0].split('@')[0]

    @account_id, @inbox_id, @conversation_id = email_first_part.match(EMAIL_PART_PATTERN).captures if email_first_part.match(EMAIL_PART_PATTERN)
  end

  def verify_decoded_params
    raise 'Account id not found' if account_id.nil?
    raise 'Inbox id not found' if inbox_id.nil?
    raise 'Conversation id not found' if conversation_id.nil?
  end

  def find_account
    @account = Account.find account_id
    validate_resource @account
  end

  def find_inbox
    @inbox = @account.inboxes.find inbox_id
    validate_resource @inbox
  end

  def find_conversation
    @conversation = @inbox.conversations.find conversation_id
    validate_resource @conversation
  end

  def validate_resource(resource)
    raise "#{resource.class.name} not found" if resource.nil?

    resource
  end

  def process_email
    @processed_email = EmailContentExtractor.new(mail)
  end
end
