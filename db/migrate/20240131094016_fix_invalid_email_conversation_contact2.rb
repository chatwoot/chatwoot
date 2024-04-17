class FixInvalidEmailConversationContact2 < ActiveRecord::Migration[7.0]
  def change
    # webflow_email = '{{email}}@loopia.invalid'
    # messages = Message.where("content_attributes::text LIKE '%#{webflow_email}%'")
    # puts "Found #{messages.count} messages with #{webflow_email}"
    # conversations = Conversation.where(id: messages.pluck(:conversation_id).uniq)
    # puts "Found #{conversations.count} conversations with #{webflow_email}"

    # conversations.each do |conversation|
    #   FixInvalidConversation.new(conversation).call
    # end
  end

  class FixInvalidConversation
    attr_accessor :conversation, :contact, :contact_inbox

    def initialize(conversation)
      @conversation = conversation
    end

    def call
      return if conversation.blank?
      return if conversation.resolved?
      return if conversation.messages.blank?
      return if conversation.messages.count > 1
      return if first_message.present?
      return if email_from_body.blank?

      find_or_create_original_contact
      fix_conversation_contact
      fix_message_email
      Rails.logger.debug { "\n Successfully fix conversation data! #{conversation.id}" }
    end

    private

    def fix_conversation_contact
      return if @contact.blank?

      conversation.update_column(:contact_id, @contact.id)
      Rails.logger.debug '.'
    end

    def fix_message_email
      msg = first_message
      msg.content_attributes[:email][:from] = [email_from_body]
      msg.save
    end

    def inbox
      conversation.inbox
    end

    def messages
      conversation.messages
    end

    def first_message
      messages.first
    end

    def email_from_body
      return @email_from_body if defined?(@email_from_body)

      email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
      match = first_message.content.match(email_regex)
      return if match.nil?

      @email_from_body = match[0]
    end

    def find_or_create_original_contact
      @contact = Contact.find_by(email: email_from_body)

      if @contact.present?
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
end
