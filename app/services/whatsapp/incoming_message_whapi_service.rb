class Whatsapp::IncomingMessageWhapiService
    pattr_initialize [:inbox!, :params!]
    
    def perform
      # Process different types of events from Whapi webhooks
      if message_event?
        process_message
      elsif status_event?
        process_status_update
      end
    end
    
    private
    
    def message_event?
      params[:messages].present?
    end
    
    def status_event?
      params[:status].present?
    end
    
    def process_message
      # Get message data from the Whapi webhook payload
      message_data = params[:messages]&.first
      return if message_data.blank?
      
      # Extract sender, message ID, timestamp, etc.
      phone_number = message_data[:from]
      message_id = message_data[:id]
      message_type = message_data[:type]
      timestamp = Time.at(message_data[:timestamp].to_i)
      
      # Find or create contact
      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: phone_number,
        inbox: inbox,
        contact_attributes: { name: contact_name || phone_number }
      ).perform
      
      # Find or create conversation
      conversation = ::Conversation.find_or_initialize_by(
        inbox_id: inbox.id,
        contact_inbox_id: contact_inbox.id
      )
      
      # Set conversation attributes if it's new
      if conversation.new_record?
        conversation.status = :open
        conversation.save!
      end
      
      # Check if message already exists
      return if conversation.messages.where(source_id: message_id).exists?
      
      # Process based on message type
      case message_type
      when 'text'
        create_text_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
      when 'image', 'video', 'audio', 'document'
        create_attachment_message(conversation, contact_inbox.contact, message_data, message_type, message_id, timestamp)
      when 'location'
        create_location_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
      end
    end
    
    def process_status_update
      # Process delivery and read receipts
      status_data = params[:status]
      return if status_data.blank?
      
      message_id = status_data[:id]
      status = status_data[:status]
      
      # Find the message in our system
      message = Message.find_by(source_id: message_id)
      return if message.blank?
      
      # Update message status
      case status
      when 'delivered'
        message.update(status: 'delivered')
      when 'read'
        message.update(status: 'read')
      when 'failed'
        message.update(status: 'failed', external_error: status_data[:error])
      end
    end
    
    def create_text_message(conversation, sender, message_data, message_id, timestamp)
      conversation.messages.create!(
        content: message_data[:text][:body],
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp
      )
    end
    
    def create_attachment_message(conversation, sender, message_data, type, message_id, timestamp)
      media_data = message_data[type.to_sym]
      return if media_data.blank?
      
      attachment_url = media_data[:url]
      media_id = media_data[:id]
      mime_type = media_data[:mime_type]
      
      # Create a file from the URL
      attachment_file = Down.download(
        attachment_url,
        headers: inbox.channel.api_headers
      )
      
      # Create the message with attachment
      message = conversation.messages.build(
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        content: message_data[:caption] || ''
      )
      
      message.attachments.new(
        account_id: conversation.account_id,
        file_type: mime_type,
        file: {
          io: attachment_file,
          filename: attachment_file.original_filename || "#{type}.#{mime_type.split('/').last}",
          content_type: mime_type
        }
      )
      
      message.save!
    end
    
    def create_location_message(conversation, sender, message_data, message_id, timestamp)
      location_data = message_data[:location]
      return if location_data.blank?
      
      latitude = location_data[:latitude]
      longitude = location_data[:longitude]
      
      conversation.messages.create!(
        content: "Location: https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}",
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp
      )
    end
    
    def contact_name
      # Extract contact name from Whapi payload if available
      params[:contacts]&.first&.dig(:profile, :name)
    end
  end