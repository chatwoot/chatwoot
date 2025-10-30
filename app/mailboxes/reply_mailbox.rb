class ReplyMailbox < ApplicationMailbox
  attr_accessor :conversation, :processed_mail

  before_processing :find_conversation

  def process
    # ConversationFinder with NewConversationStrategy ensures @conversation is always present
    decorate_mail
    create_message
    add_attachments_to_message
  end

  private

  def find_conversation
    @conversation = Mailbox::ConversationFinder.new(mail).find
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
