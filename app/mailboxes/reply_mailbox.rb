class ReplyMailbox < ApplicationMailbox
  attr_accessor :conversation, :processed_mail

  before_processing :find_conversation

  def process
    # Return early if no conversation was found (e.g., notification emails, suspended accounts)
    return unless @conversation

    # Wrap everything in a transaction to ensure atomicity
    # This prevents orphan conversations if message/attachment creation fails
    # and ensures idempotency on job retry (conversation won't be duplicated)
    ActiveRecord::Base.transaction do
      persist_conversation_if_needed
      decorate_mail
      create_message
      add_attachments_to_message
    end
  end

  private

  def find_conversation
    @conversation = Mailbox::ConversationFinder.new(mail).find
    # Log when email is rejected
    Rails.logger.info "Email #{mail.message_id} rejected - no conversation found" unless @conversation
  end

  def persist_conversation_if_needed
    # Save the conversation if it's a new record (from NewConversationStrategy)
    # We persist here instead of in the strategy to maintain transaction integrity
    return unless @conversation.new_record?

    @conversation.save!
    Rails.logger.info "Created new conversation #{@conversation.id} for email #{mail.message_id}"
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(mail, @conversation.account)
  end
end
