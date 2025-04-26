class Facebook::DirectMessageService
  attr_reader :channel, :user_id, :content
  
  def initialize(channel:, user_id:, content:)
    @channel = channel
    @user_id = user_id
    @content = content
  end
  
  def send
    begin
      graph = Koala::Facebook::API.new(channel.page_access_token)
      response = graph.put_connections(
        "me",
        "messages",
        recipient: { id: user_id },
        message: { text: content }
      )
      
      if response && response['message_id']
        # Tạo tin nhắn trong Chatwoot
        create_message_in_chatwoot
        
        Rails.logger.info "Successfully sent direct message to Facebook user: #{user_id}"
        return {
          success: true,
          data: {
            message_id: response['message_id'],
            recipient_id: user_id
          }
        }
      else
        Rails.logger.warn "Failed to send direct message to Facebook user: #{user_id}"
        return {
          success: false,
          error: 'Failed to send message'
        }
      end
    rescue => e
      Rails.logger.error "Error sending Facebook direct message: #{e.message}"
      return {
        success: false,
        error: e.message
      }
    end
  end
  
  private
  
  def create_message_in_chatwoot
    # Tìm hoặc tạo contact và conversation
    contact = find_or_create_contact
    contact_inbox = find_or_create_contact_inbox(contact)
    conversation = find_or_create_conversation(contact, contact_inbox)
    
    # Tạo tin nhắn
    Messages::MessageBuilder.new(
      nil,
      conversation,
      {
        content: content,
        message_type: :outgoing,
        private: false
      }
    ).perform
  end
  
  def find_or_create_contact
    contact = Contact.find_or_initialize_by(
      account_id: channel.account_id,
      identifier: "facebook:#{user_id}"
    )
    
    unless contact.persisted?
      # Lấy thông tin người dùng từ Facebook
      user_data = Facebook::FetchProfileService.new(
        user_id: user_id,
        page_access_token: channel.page_access_token
      ).perform
      
      contact.name = "#{user_data['first_name'] || ''} #{user_data['last_name'] || ''}".strip
      contact.name = "Facebook User" if contact.name.blank?
      contact.save!
    end
    
    contact
  end
  
  def find_or_create_contact_inbox(contact)
    contact_inbox = ContactInbox.find_or_initialize_by(
      contact_id: contact.id,
      inbox_id: channel.inbox.id
    )
    
    unless contact_inbox.persisted?
      contact_inbox.source_id = user_id
      contact_inbox.save!
    end
    
    contact_inbox
  end
  
  def find_or_create_conversation(contact, contact_inbox)
    conversation = Conversation.find_or_initialize_by(
      contact_id: contact.id,
      inbox_id: channel.inbox.id,
      status: :open
    )
    
    unless conversation.persisted?
      conversation.account_id = channel.account_id
      conversation.contact_inbox_id = contact_inbox.id
      conversation.save!
    end
    
    conversation
  end
end
