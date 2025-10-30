class Mailbox::ConversationFinderStrategies::NewConversationStrategy < Mailbox::ConversationFinderStrategies::BaseStrategy
  include MailboxHelper

  attr_accessor :processed_mail, :account, :inbox, :contact, :contact_inbox, :conversation

  # This strategy always succeeds by creating a new conversation if none was found.
  # It should be used as the last strategy in the chain to ensure emails are never dropped.
  def find
    channel = EmailChannelFinder.new(mail).perform
    return nil unless channel # No valid channel found

    @account = channel.account
    @inbox = channel.inbox
    @processed_mail = MailPresenter.new(mail, @account)

    ActiveRecord::Base.transaction do
      find_or_create_contact
      create_conversation
    end

    @conversation
  end

  private

  def find_or_create_contact
    @contact = @inbox.contacts.from_email(original_sender_email)
    if @contact.present?
      @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact)
    else
      create_contact
    end
  end

  def original_sender_email
    @processed_mail.original_sender&.downcase
  end

  def identify_contact_name
    @processed_mail.sender_name || @processed_mail.from.first.split('@').first
  end

  def create_conversation
    @conversation = ::Conversation.create!(
      account_id: @account.id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        in_reply_to: in_reply_to,
        source: 'email',
        auto_reply: @processed_mail.auto_reply?,
        mail_subject: @processed_mail.subject,
        initiated_at: {
          timestamp: Time.now.utc
        }
      }
    )
  end

  def in_reply_to
    mail['In-Reply-To'].try(:value)
  end
end
