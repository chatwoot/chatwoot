class Whatsapp::IncomingMessageWhapiService
    pattr_initialize [:inbox!, :params!]
    
    def perform
      Rails.logger.info("WHAPI Service starting to process webhook: #{inbox.id}")
      
      # Process different types of events from Whapi webhooks
      if message_event?
        process_message
      elsif status_event?
        process_status_update
      end
      
      # Log if we can't process the event
      if !message_event? && !status_event?
        Rails.logger.info("WHAPI unprocessed event type: #{params.dig(:event, :type)}")
      end
      
      Rails.logger.info("WHAPI Service finished processing webhook")
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
      
      Rails.logger.info("WHAPI processing message: #{message_data.inspect}")
      
      # Handle outgoing messages differently
      if outgoing_message?(message_data)
        message_id = message_data[:id]
        Rails.logger.info("WHAPI received update for outgoing message: #{message_id}")
        
        # Try to find the message in our system by source_id
        existing_message = Message.find_by(source_id: message_id)
        
        if existing_message.present?
          Rails.logger.info("WHAPI found existing outgoing message #{existing_message.id}, updating status")
          existing_message.update(status: 'sent')
          return
        else
          Rails.logger.info("WHAPI skipping processing of outgoing message - not found in our system: #{message_id}")
          return
        end
      end
      
      # Extract sender, message ID, timestamp, etc.
      phone_number = message_data[:from]
      message_id = message_data[:id]
      message_type = message_data[:type]
      timestamp = Time.at(message_data[:timestamp].to_i)
      
      Rails.logger.info("WHAPI extracted phone: #{phone_number}, msg_id: #{message_id}, type: #{message_type}")
      
      # Find or create contact
      begin
        contact_inbox = ::ContactInboxWithContactBuilder.new(
          source_id: phone_number,
          inbox: inbox,
          contact_attributes: { name: contact_name || phone_number }
        ).perform
        
        Rails.logger.info("WHAPI found/created contact_inbox: #{contact_inbox.id} for contact: #{contact_inbox.contact.id}")
        
        # Update contact with additional WhatsApp Profile information if available
        update_contact_with_whatsapp_profile(contact_inbox.contact) if params[:contacts].present?
        
        # Find or create conversation with explicit account and contact IDs
        Rails.logger.info("WHAPI looking for conversation with inbox_id: #{inbox.id}, contact_inbox_id: #{contact_inbox.id}")
        
        # Use create_with to ensure the account_id and contact_id are set when creating a new record
        conversation = ::Conversation.create_with(
          account_id: inbox.account_id,
          contact_id: contact_inbox.contact_id,
          status: :open
        ).find_or_initialize_by(
          inbox_id: inbox.id,
          contact_inbox_id: contact_inbox.id
        )
        
        # Double-check the values are properly set
        conversation.account_id = inbox.account_id if conversation.account_id.blank?
        conversation.contact_id = contact_inbox.contact_id if conversation.contact_id.blank?
        
        Rails.logger.info("WHAPI conversation attributes: account_id=#{conversation.account_id}, contact_id=#{conversation.contact_id}")
        
        if conversation.new_record?
          Rails.logger.info("WHAPI creating new conversation for inbox: #{inbox.id}, contact: #{contact_inbox.contact.id}, account: #{inbox.account_id}")
          conversation.save!
          Rails.logger.info("WHAPI conversation created with ID: #{conversation.id}")
        else
          Rails.logger.info("WHAPI found existing conversation: #{conversation.id}")
        end
        
        # Check if message already exists
        if conversation.messages.where(source_id: message_id).exists?
          Rails.logger.info("WHAPI message already exists, skipping: #{message_id}")
          return
        end
        
        # Process based on message type
        case message_type
        when 'text'
          message = create_text_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created text message: #{message.id if message}")
        when 'image', 'video', 'audio', 'document'
          message = create_attachment_message(conversation, contact_inbox.contact, message_data, message_type, message_id, timestamp)
          Rails.logger.info("WHAPI created attachment message: #{message.id if message}")
        when 'location'
          message = create_location_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created location message: #{message.id if message}")
        when 'contact', 'contact_list'
          message = create_contact_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created contact message: #{message.id if message}")
        when 'interactive'
          message = create_interactive_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created interactive message: #{message.id if message}")
        when 'button'
          message = create_button_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created button message: #{message.id if message}")
        when 'sticker'
          message = create_sticker_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created sticker message: #{message.id if message}")
        when 'voice'
          message = create_voice_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created voice message: #{message.id if message}")
        when 'reaction'
          message = create_reaction_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created reaction message: #{message.id if message}")
        when 'poll'
          message = create_poll_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created poll message: #{message.id if message}")
        when 'link_preview'
          message = create_link_preview_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
          Rails.logger.info("WHAPI created link preview message: #{message.id if message}")
        else
          # Default handling for unsupported types
          message = create_text_message(
            conversation, 
            contact_inbox.contact, 
            { text: { body: "Unsupported message type: #{message_type}" } }, 
            message_id, 
            timestamp
          )
          Rails.logger.info("WHAPI created unsupported type message: #{message.id if message}")
        end
      rescue => e
        Rails.logger.error("WHAPI message processing error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
    end
    
    def process_status_update
      # Process delivery and read receipts
      status_data = params[:status]
      return if status_data.blank?
      
      message_id = status_data[:id]
      status = status_data[:status]
      is_outgoing = status_data[:from_me] == true
      
      Rails.logger.info("WHAPI processing status update: message_id=#{message_id}, status=#{status}, outgoing=#{is_outgoing}")
      
      # Find the message in our system
      message = Message.find_by(source_id: message_id)
      
      if message.blank?
        # Let's check if this might be an outgoing message with a different source_id format
        Rails.logger.info("WHAPI status update: message not found with source_id: #{message_id}")
        
        # If this is for an outgoing message, try to find the conversation by phone number
        if is_outgoing && status_data[:to].present?
          Rails.logger.info("WHAPI attempting to find conversation for outgoing message to: #{status_data[:to]}")
          contact_inbox = inbox.contact_inboxes.find_by(source_id: status_data[:to])
          
          if contact_inbox.present?
            # Find the most recent outgoing message in this conversation
            conversation = contact_inbox.conversations.last
            if conversation.present?
              recent_message = conversation.messages.where(message_type: :outgoing).order(created_at: :desc).first
              
              if recent_message.present?
                Rails.logger.info("WHAPI found recent outgoing message #{recent_message.id} - updating status")
                recent_message.update(status: status, source_id: message_id)
                return
              end
            end
          end
        end
        
        return
      end
      
      # Update message status
      case status
      when 'sent', 'delivered'
        message.update(status: status)
        Rails.logger.info("WHAPI updated message status to #{status}: #{message.id}")
      when 'read'
        message.update(status: 'read')
        Rails.logger.info("WHAPI updated message status to read: #{message.id}")
      when 'failed'
        message.update(status: 'failed', external_error: status_data[:error])
        Rails.logger.info("WHAPI updated message status to failed: #{message.id}, error: #{status_data[:error]}")
      end
    end
    
    def create_text_message(conversation, sender, message_data, message_id, timestamp)
      # Handle quoted messages if present
      quoted_message_details = extract_quoted_message_details(message_data[:context])
      
      conversation.messages.create!(
        content: message_data[:text][:body],
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content_attributes: quoted_message_details.present? ? { quoted_message: quoted_message_details } : {}
      )
    end
    
    def create_attachment_message(conversation, sender, message_data, type, message_id, timestamp)
      media_data = message_data[type.to_sym]
      return if media_data.blank?
      
      attachment_url = media_data[:url] || media_data[:link]
      media_id = media_data[:id]
      mime_type = media_data[:mime_type]
      caption = media_data[:caption] || ''
      
      # Create a file from the URL
      begin
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
          content: caption
        )
        
        message.attachments.new(
          account_id: conversation.account_id,
          file_type: mime_type,
          file: {
            io: attachment_file,
            filename: media_data[:file_name] || attachment_file.original_filename || "#{type}.#{mime_type.split('/').last}",
            content_type: mime_type
          }
        )
        
        message.save!
      rescue => e
        Rails.logger.error "Failed to download WHAPI attachment: #{e.message}"
        
        # Create a text message instead with link to the content
        conversation.messages.create!(
          content: "#{caption}\n\n[#{type.capitalize} attachment](#{attachment_url})",
          message_type: :incoming,
          sender: sender,
          source_id: message_id,
          created_at: timestamp,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        )
      end
    end
    
    def create_location_message(conversation, sender, message_data, message_id, timestamp)
      location_data = message_data[:location]
      return if location_data.blank?
      
      latitude = location_data[:latitude]
      longitude = location_data[:longitude]
      address = location_data[:address]
      name = location_data[:name]
      
      location_text = "Location"
      location_text += ": #{name}" if name.present?
      location_text += " (#{address})" if address.present?
      location_text += "\nhttps://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}"
      
      conversation.messages.create!(
        content: location_text,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id
      )
    end
    
    def create_contact_message(conversation, sender, message_data, message_id, timestamp)
      contact_data = message_data[:contact] || message_data[:contact_list]
      return if contact_data.blank?
      
      if message_data[:type] == 'contact_list' && contact_data[:list].present?
        # Handle contact list
        contacts = contact_data[:list]
        contact_text = "Contact List:\n"
        
        contacts.each do |contact|
          contact_text += "- #{contact[:name]}\n"
        end
      else
        # Handle single contact
        contact_text = "Contact: #{contact_data[:name]}"
      end
      
      conversation.messages.create!(
        content: contact_text,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id
      )
    end
    
    def create_interactive_message(conversation, sender, message_data, message_id, timestamp)
      interactive_data = message_data[:interactive]
      return if interactive_data.blank?
      
      # Extract the content based on the type of interactive message
      header_text = interactive_data.dig(:header, :text) || ''
      body_text = interactive_data.dig(:body, :text) || ''
      footer_text = interactive_data.dig(:footer, :text) || ''
      
      # Extract the selected option if any
      selected_option = ''
      if interactive_data[:type] == 'button_reply'
        selected_option = interactive_data.dig(:action, :button) || ''
      elsif interactive_data[:type] == 'list_reply'
        selected_option = interactive_data.dig(:action, :row, :title) || ''
      end
      
      # Construct the message content
      content = ""
      content += "#{header_text}\n" if header_text.present?
      content += "#{body_text}\n" if body_text.present?
      content += "Selected: #{selected_option}\n" if selected_option.present?
      content += "#{footer_text}" if footer_text.present?
      
      conversation.messages.create!(
        content: content.strip,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content_attributes: {
          interactive_type: interactive_data[:type],
          interactive_selected: selected_option
        }
      )
    end
    
    def create_button_message(conversation, sender, message_data, message_id, timestamp)
      button_data = message_data[:button]
      return if button_data.blank?
      
      button_text = button_data[:text]
      
      conversation.messages.create!(
        content: "Button: #{button_text}",
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id
      )
    end
    
    def create_sticker_message(conversation, sender, message_data, message_id, timestamp)
      sticker_data = message_data[:sticker]
      return if sticker_data.blank?
      
      begin
        # Try to download the sticker as an image
        attachment_url = sticker_data[:url] || sticker_data[:link]
        
        if attachment_url.present?
          attachment_file = Down.download(
            attachment_url,
            headers: inbox.channel.api_headers
          )
          
          # Create the message with sticker as an attachment
          message = conversation.messages.build(
            message_type: :incoming,
            sender: sender,
            source_id: message_id,
            created_at: timestamp,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            content: 'Sticker'
          )
          
          message.attachments.new(
            account_id: conversation.account_id,
            file_type: 'image/webp',
            file: {
              io: attachment_file,
              filename: 'sticker.webp',
              content_type: 'image/webp'
            }
          )
          
          message.save!
        else
          conversation.messages.create!(
            content: 'Sent a sticker',
            message_type: :incoming,
            sender: sender,
            source_id: message_id,
            created_at: timestamp
          )
        end
      rescue => e
        Rails.logger.error "Failed to download WHAPI sticker: #{e.message}"
        
        conversation.messages.create!(
          content: 'Sent a sticker',
          message_type: :incoming,
          sender: sender,
          source_id: message_id,
          created_at: timestamp
        )
      end
    end
    
    def create_voice_message(conversation, sender, message_data, message_id, timestamp)
      voice_data = message_data[:voice]
      return if voice_data.blank?
      
      # Similar to audio message but marked as voice
      begin
        attachment_url = voice_data[:url] || voice_data[:link]
        
        if attachment_url.present?
          attachment_file = Down.download(
            attachment_url,
            headers: inbox.channel.api_headers
          )
          
          # Create the message with voice as an attachment
          message = conversation.messages.build(
            message_type: :incoming,
            sender: sender,
            source_id: message_id,
            created_at: timestamp,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            content: 'Voice message'
          )
          
          message.attachments.new(
            account_id: conversation.account_id,
            file_type: voice_data[:mime_type] || 'audio/ogg',
            file: {
              io: attachment_file,
              filename: 'voice_message.ogg',
              content_type: voice_data[:mime_type] || 'audio/ogg'
            }
          )
          
          message.save!
        else
          conversation.messages.create!(
            content: 'Voice message',
            message_type: :incoming,
            sender: sender,
            source_id: message_id,
            created_at: timestamp,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id
          )
        end
      rescue => e
        Rails.logger.error "Failed to download WHAPI voice message: #{e.message}"
        
        conversation.messages.create!(
          content: 'Voice message',
          message_type: :incoming,
          sender: sender,
          source_id: message_id,
          created_at: timestamp,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        )
      end
    end
    
    def create_reaction_message(conversation, sender, message_data, message_id, timestamp)
      action_data = message_data[:action]
      return if action_data.blank?
      
      reaction_emoji = action_data[:emoji]
      target_message_id = action_data[:target]
      
      # Find the target message if it exists
      target_message = conversation.messages.find_by(source_id: target_message_id)
      content = reaction_emoji.present? ? "Reacted with #{reaction_emoji}" : "Removed reaction"
      
      if target_message
        # Update the target message with the reaction
        current_reactions = target_message.content_attributes[:reactions] || {}
        sender_id = sender.id.to_s
        
        if reaction_emoji.present?
          current_reactions[sender_id] = reaction_emoji
        else
          current_reactions.delete(sender_id)
        end
        
        target_message.update(content_attributes: target_message.content_attributes.merge(reactions: current_reactions))
      else
        # If target message doesn't exist, create a new message about the reaction
        conversation.messages.create!(
          content: content,
          message_type: :incoming,
          sender: sender,
          source_id: message_id,
          created_at: timestamp,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        )
      end
    end
    
    def create_poll_message(conversation, sender, message_data, message_id, timestamp)
      poll_data = message_data[:poll]
      return if poll_data.blank?
      
      title = poll_data[:title]
      options = poll_data[:options]
      
      poll_content = "Poll: #{title}\nOptions:"
      options.each do |option|
        poll_content += "\n- #{option}"
      end
      
      conversation.messages.create!(
        content: poll_content,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content_attributes: {
          poll_title: title,
          poll_options: options
        }
      )
    end
    
    def create_link_preview_message(conversation, sender, message_data, message_id, timestamp)
      link_data = message_data[:link_preview]
      return if link_data.blank?
      
      body = link_data[:body]
      url = link_data[:url]
      title = link_data[:title]
      description = link_data[:description]
      
      content = ""
      content += "#{body}\n\n" if body.present?
      content += "#{title}\n" if title.present?
      content += "#{description}\n" if description.present?
      content += url if url.present?
      
      conversation.messages.create!(
        content: content,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        created_at: timestamp,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id
      )
    end
    
    def contact_name
      # Extract contact name from Whapi payload if available
      params[:contacts]&.first&.dig(:profile, :name)
    end
    
    def update_contact_with_whatsapp_profile(contact)
      contact_data = params[:contacts]&.first
      return if contact_data.blank?
      
      profile = contact_data[:profile] || {}
      
      # Update contact with profile data if available
      contact_update_params = {}
      
      # Name from profile
      contact_update_params[:name] = profile[:name] if profile[:name].present?
      
      # Additional custom attributes from WhatsApp profile
      additional_attributes = contact.additional_attributes || {}
      
      if profile[:about].present?
        additional_attributes[:about] = profile[:about]
      end
      
      contact_update_params[:additional_attributes] = additional_attributes if additional_attributes.any?
      
      contact.update(contact_update_params) if contact_update_params.any?
    end
    
    def extract_quoted_message_details(context)
      return {} if context.blank? || context[:quoted_id].blank?
      
      quoted_id = context[:quoted_id]
      quoted_message = Message.find_by(source_id: quoted_id)
      
      if quoted_message.present?
        {
          id: quoted_message.id,
          content: quoted_message.content,
          sender: {
            id: quoted_message.sender_id,
            name: quoted_message.sender&.name || context[:quoted_author] || 'Unknown'
          }
        }
      else
        {
          id: nil,
          content: context[:quoted_content].present? ? context[:quoted_content][:body] : '',
          sender: {
            id: nil,
            name: context[:quoted_author] || 'Unknown'
          }
        }
      end
    end
    
    # Helper to identify messages from our system
    def outgoing_message?(message_data)
      return true if message_data[:from_me] == true
      
      # Sometimes providers use different flags, check alternative fields too
      return true if message_data[:direction] == 'outbound'
      return true if message_data[:type] == 'outbound'
      
      false
    end
  end