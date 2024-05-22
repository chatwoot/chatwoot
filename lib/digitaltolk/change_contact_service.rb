class Digitaltolk::ChangeContactService
  attr_accessor :account, :contact, :conversation, :email, :inbox

  def initialize(account, conversation, email)
    @account = account
    @conversation = conversation
    @email = email.to_s.strip.downcase
    @inbox = conversation.inbox
  end

  def perform
    return false unless Digitaltolk::MailHelper::EMAIL_REGEX.match?(@email)

    ActiveRecord::Base.transaction do
      find_or_create_contact
      change_conversation_contact
      @email == @conversation.contact.email
    end
  rescue StandardError => e
    Rails.logger.warn e
    Rails.logger.warn e.backtrace.first
    false
  end

  private

  def change_conversation_contact
    @conversation.update(contact: @contact, contact_inbox: @contact_inbox)
  end

  def find_or_create_contact
    @contact = @account.contacts.find_by(email: @email)

    if @contact.blank?
      @contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: @email,
        inbox: @inbox,
        contact_attributes: {
          name: identify_contact_name,
          email: @email,
          additional_attributes: {
            source_id: "email:#{source_id}"
          }
        }
      ).perform

      @contact = @contact_inbox.contact
    else
      @contact_inbox = @inbox.contact_inboxes.find_by(contact: @contact)

      if @contact_inbox.blank?
        @contact_inbox = ContactInboxBuilder.new(
          contact: @contact,
          inbox: @inbox,
          source_id: @email
        ).perform
      end
    end
  end

  def identify_contact_name
    @email.split('@').first.to_s.titleize
  end

  def source_id
    @conversation.messages.incoming.first&.source_id
  end
end
