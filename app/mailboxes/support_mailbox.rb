class SupportMailbox < ApplicationMailbox
  include MailboxHelper

  attr_accessor :channel, :account, :inbox, :conversation, :processed_mail

  before_processing :find_channel,
                    :find_conversation_with_recipient,
                    :load_account,
                    :load_inbox,
                    :decorate_mail

  def process
    ActiveRecord::Base.transaction do
      find_or_create_contact
      create_conversation
      create_message
      add_attachments_to_message
    end
  end

  private

  def find_channel
    mail.to.each do |email|
      @channel = Channel::Email.find_by('lower(email) = ? OR lower(forward_to_email) = ?', email.downcase, email.downcase)
      break if @channel.present?
    end
    raise 'Email channel/inbox not found' if @channel.nil?

    @channel
  end

  def find_conversation_with_recipient
    conversations = recipient_email_channel_conversations
    return unless conversations.any?

    @conversation = conversations.last
    @conversation_uuid = @conversation.uuid
  end

  def recipient_email_channel_conversations
    inbox = @channel.try(:inbox)
    collect_conversations(inbox)
  end

  def collect_conversations(inbox)
    return if inbox.nil?

    inbox.conversations.open.joins(:contact).where(
      "conversations.additional_attributes ->> 'mail_subject' = ? AND contacts.email IN (?)",
      mail.subject, mail.from
    )
  end

  def load_account
    @account = @channel.account
  end

  def load_inbox
    @inbox = @channel.inbox
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @account)
  end

  def create_conversation
    return if @conversation.present?

    @conversation = ::Conversation.create!({
                                             account_id: @account.id,
                                             inbox_id: @inbox.id,
                                             contact_id: @contact.id,
                                             contact_inbox_id: @contact_inbox.id,
                                             additional_attributes: {
                                               source: 'email',
                                               mail_subject: @processed_mail.subject,
                                               initiated_at: {
                                                 timestamp: Time.now.utc
                                               }
                                             }
                                           })
  end

  def find_or_create_contact
    @contact = @inbox.contacts.find_by(email: @processed_mail.original_sender)
    if @contact.present?
      @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact)
    else
      create_contact
    end
  end

  def create_contact
    @contact_inbox = ::ContactBuilder.new(
      source_id: "email:#{processed_mail.message_id}",
      inbox: @inbox,
      contact_attributes: {
        name: identify_contact_name,
        email: @processed_mail.original_sender,
        additional_attributes: {
          source_id: "email:#{processed_mail.message_id}"
        }
      }
    ).perform
    @contact = @contact_inbox.contact
  end

  def identify_contact_name
    processed_mail.sender_name || processed_mail.from.first.split('@').first
  end
end
