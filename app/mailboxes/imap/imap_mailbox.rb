class Imap::ImapMailbox
  include MailboxHelper
  include IncomingEmailValidityHelper
  attr_accessor :channel, :account, :inbox, :conversation, :processed_mail

  def process(mail, channel)
    @inbound_mail = mail
    @channel = channel
    load_account
    load_inbox
    decorate_mail

    Rails.logger.info("Processing Email from: #{@processed_mail.original_sender} : inbox #{@inbox.id} : message_id #{@processed_mail.message_id}")

    # Skip processing email if it belongs to any of the edge cases
    return unless incoming_email_from_valid_email?

    ActiveRecord::Base.transaction do
      find_or_create_contact
      find_or_create_conversation
      create_message
      add_attachments_to_message
    end
  end

  private

  def load_account
    @account = @channel.account
  end

  def load_inbox
    @inbox = @channel.inbox
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(@inbound_mail, @account)
  end

  def find_conversation_by_in_reply_to
    return if in_reply_to.blank?

    message = @inbox.messages.find_by(source_id: in_reply_to)
    if message.nil?
      @inbox.conversations.where("additional_attributes->>'in_reply_to' = ?", in_reply_to).first
    else
      @inbox.conversations.find(message.conversation_id)
    end
  end

  def find_conversation_by_reference_ids
    return if @inbound_mail.references.blank? && in_reply_to.present?

    message = find_message_by_references

    return if message.nil?

    @inbox.conversations.find(message.conversation_id)
  end

  def in_reply_to
    @processed_mail.in_reply_to
  end

  def find_message_by_references
    message_to_return = nil

    references = Array.wrap(@inbound_mail.references)

    references.each do |message_id|
      message = @inbox.messages.find_by(source_id: message_id)
      message_to_return = message if message.present?
    end
    message_to_return
  end

  def find_or_create_conversation
    @conversation = find_conversation_by_in_reply_to || find_conversation_by_reference_ids || ::Conversation.create!(
      {
        account_id: @account.id,
        inbox_id: @inbox.id,
        contact_id: @contact.id,
        contact_inbox_id: @contact_inbox.id,
        additional_attributes: {
          source: 'email',
          in_reply_to: in_reply_to,
          mail_subject: @processed_mail.subject,
          initiated_at: {
            timestamp: Time.now.utc
          }
        }
      }
    )
  end

  def find_or_create_contact
    @contact = @inbox.contacts.from_email(@processed_mail.original_sender)
    if @contact.present?
      @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact)
    else
      create_contact
    end
  end

  def identify_contact_name
    processed_mail.sender_name || processed_mail.from.first.split('@').first
  end
end
