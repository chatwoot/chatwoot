class ReplyMailbox < ApplicationMailbox
  attr_accessor :conversation, :processed_mail

  before_processing :find_conversation

  def process
    # Return early if no conversation was found (e.g., notification emails, suspended accounts)
    return unless @conversation

    decorate_mail
    create_message
    add_attachments_to_message
  end

  private

  def find_conversation
    @conversation = Mailbox::ConversationFinder.new(mail).find
    # Log when email is rejected
    Rails.logger.info "Email #{mail.message_id} rejected - no conversation found" unless @conversation
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
