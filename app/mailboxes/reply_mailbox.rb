class ReplyMailbox < ApplicationMailbox
  attr_accessor :conversation, :processed_mail

  before_processing :find_conversation

  def process
    return if @conversation.blank?

    decorate_mail
    create_message
    add_attachments_to_message
  end

  private

  def find_conversation
    @conversation = Mailbox::ConversationFinderChain.new(mail).find

    return unless @conversation.nil?

    Rails.logger.error "[ReplyMailbox] No conversation found for email #{mail.message_id}"
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
