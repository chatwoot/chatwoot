class Imap::ImapMailbox
  include MailboxHelper
  attr_accessor :channel, :account, :inbox, :conversation, :processed_mail

  # before :find_channel
  # :load_account,
  # :load_inbox,
  # :decorate_mail

  def process(mail)
    @inbound_mail = mail
    find_channel
    load_account
    load_inbox
    decorate_mail

    ActiveRecord::Base.transaction do
      find_or_create_contact
      find_or_create_conversation
      create_message
      # add_attachments_to_message
    end
  end

  private

  def find_channel
    @channel = Channel::Email.find_by('lower(imap_email) = ? ', @inbound_mail.to)
    raise 'Email channel/inbox not found' if @channel.nil?

    @channel
  end

  def load_account
    @account = @channel.account
  end

  def load_inbox
    @inbox = @channel.inbox
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(@inbound_mail, @account)
  end

  def find_conversation_by_message_id
    @account.conversations.where("additional_attributes->>'message_id' = ?", @processed_mail.message_id).first
  end

  def find_or_create_conversation
    @conversation = find_conversation_by_message_id || ::Conversation.create!({
                                                                                account_id: @account.id,
                                                                                inbox_id: @inbox.id,
                                                                                contact_id: @contact.id,
                                                                                contact_inbox_id: @contact_inbox.id,
                                                                                additional_attributes: {
                                                                                  source: 'email',
                                                                                  mail_subject: @processed_mail.subject,
                                                                                  message_id: @processed_mail.message_id,
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
