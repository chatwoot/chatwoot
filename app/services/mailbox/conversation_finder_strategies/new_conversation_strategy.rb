class Mailbox::ConversationFinderStrategies::NewConversationStrategy < Mailbox::ConversationFinderStrategies::BaseStrategy
  include MailboxHelper
  include IncomingEmailValidityHelper

  attr_accessor :processed_mail, :account, :inbox, :contact, :contact_inbox, :conversation, :channel

  def initialize(mail)
    super(mail)
    @channel = EmailChannelFinder.new(mail).perform
    return unless @channel

    @account = @channel.account
    @inbox = @channel.inbox
    @processed_mail = MailPresenter.new(mail, @account)
  end

  # This strategy prepares a new conversation but doesn't persist it yet.
  # Why we don't use create! here:
  # - Avoids orphan conversations if message/attachment creation fails later
  # - Prevents duplicate conversations on job retry (no idempotency issue)
  # - Follows the pattern from old SupportMailbox where everything was in one transaction
  # The actual persistence happens in ReplyMailbox within a transaction that includes message creation.
  def find
    return nil unless @channel # No valid channel found
    return nil unless incoming_email_from_valid_email? # Skip edge cases

    # Check if conversation already exists by in_reply_to
    existing_conversation = find_conversation_by_in_reply_to
    return existing_conversation if existing_conversation

    # Prepare contact (persisted) and build conversation (not persisted)
    find_or_create_contact
    build_conversation
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

  def build_conversation
    # Build but don't persist - ReplyMailbox will save in transaction with message
    @conversation = ::Conversation.new(
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

  def find_conversation_by_in_reply_to
    return if in_reply_to.blank?

    @account.conversations.where("additional_attributes->>'in_reply_to' = ?", in_reply_to).first
  end
end
