class Digitaltolk::FixInvalidConversation
  attr_accessor :conversation, :contact, :contact_inbox

  def initialize(conversation)
    @conversation = conversation
  end

  def call
    return if conversation.blank?
    return if conversation.messages.blank?
    return unless first_message.present?
    return unless email_from_body.present?
    puts "\n conversion_id_fixing: #{conversation.id}"

    begin
      ActiveRecord::Base.transaction do
        find_or_create_original_contact
        fix_conversation_contact
        fix_message_email
      end
      puts "\n conversion_id_fixed: #{conversation.id}"
    rescue StandardError => e
      puts "invalid_conversation_error: #{conversation.id}"
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.first
    end
  end

  private

  def fix_conversation_contact
    return if @contact.blank?

    @conversation.update_column(:contact_id, @contact.id)
    print '.'
  end

  def fix_message_email
    @conversation.messages.incoming.where("content_attributes::text LIKE '%#{Digitaltolk::MailHelper::INVALID_LOOPIA_EMAIL}%'").each do |msg|
      puts "fixing_message_id: #{msg&.id}"
      next if msg.blank?
      next if msg.content_attributes.blank?
      next if msg.content_attributes.dig(:email, :from).blank?
      next if msg.content_attributes.dig(:email, :from) != Digitaltolk::MailHelper::INVALID_LOOPIA_EMAIL
    
      msg.content_attributes[:email][:from] = [email_from_body]

      if msg.content_attributes.dig(:email, :cc).present?
        if msg.content_attributes.dig(:email, :cc).to_a.exclude?(email_from_body)
          msg.content_attributes[:email][:cc] = nil
        end
      end
      msg.save
      puts "fixed_message_id: #{msg&.id}"
    end
  end

  def inbox
    conversation.inbox
  end

  def first_message
    conversation.messages.incoming.first
  end

  def email_from_body
    return @email_from_body if defined?(@email_from_body)

    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
    match = first_message.content.to_s.match(email_regex)
    return if match.nil?
    
    @email_from_body = match[0]
  end

  def find_or_create_original_contact
    @contact = Contact.where("email LIKE '%#{email_from_body}%'").first

    if @contact.present?
      @contact.update_column(:name, identify_contact_name)
      @contact_inbox = ContactInbox.find_by(inbox: inbox, contact: @contact)
    else
      create_contact
    end
  end

  def create_contact
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: email_from_body,
      inbox: inbox,
      contact_attributes: {
        name: identify_contact_name,
        email: email_from_body
      }
    ).perform
    @contact = @contact_inbox.contact
  end

  def identify_contact_name
    email_from_body.split('@').first
  end
end