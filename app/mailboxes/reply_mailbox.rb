class ReplyMailbox < ApplicationMailbox
  include MailboxHelper

  attr_accessor :conversation_uuid, :processed_mail

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  EMAIL_PART_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i
  CONVERSATION_UUID_PATTERN = %r{^<account/(\d+?)/conversation/([a-zA-Z0-9\-]*?)@(\w+\.\w+)>$}

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
    elsif recipient_email_channel_conversations.present?
      find_conversation_with_recipient
    else
      find_conversation_with_id
    end
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

  def find_conversation_with_uuid
    @conversation = Conversation.find_by(uuid: conversation_uuid)
    validate_resource @conversation
  end

  def find_conversation_with_recipient
    @conversation = @conversations.last
    @conversation_uuid = @conversation.uuid
    validate_resource @conversation
  end

  def find_conversation_with_id
    in_reply_to_email = mail['In-Reply-To'].value
    match_result = in_reply_to_email.match(CONVERSATION_UUID_PATTERN)
    return unless match_result

    @account = Account.find_by(id: match_result.captures[0])
    return unless @account.inbound_email_domain == match_result.captures[2]

    @conversation_uuid = match_result.captures[1]
    find_conversation_with_uuid
  end

  def validate_resource(resource)
    raise "#{resource.class.name} not found" if resource.nil?

    resource
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end

  def conversation_with_recipient
    @conversation = Conversation.find_by(uuid: conversation_uuid)
  end

  def recipient_email_channel_conversations
    @conversations = []
    mail.to.each do |email|
      inbox = Channel::Email.find_by(email: email).try(:inbox)
      @conversations = collect_conversations(inbox)

      break if @conversations.any?
    end
    @conversations
  end

  def collect_conversations(inbox)
    return if inbox.nil?

    inbox.conversations.joins(:contact).where(
      "conversations.additional_attributes ->> 'mail_subject' = ? AND contacts.email IN (?)",
      mail.subject, mail.from
    )
  end
end
