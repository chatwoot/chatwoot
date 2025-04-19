class Whatsapp::IncomingMessageWhapiService
    pattr_initialize [:inbox!, :params!]
    
    def perform
      Rails.logger.info("WHAPI Service starting to process webhook: #{inbox.id}")
      Rails.logger.info("WHAPI webhook payload: #{params.inspect}")
      
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
        existing_message = find_message_by_source_id_or_content(message_id, message_data)
        
        if existing_message.present?
          Rails.logger.info("WHAPI found existing outgoing message #{existing_message.id}, updating status")
          existing_message.update(source_id: message_id, status: message_data[:status] || 'sent')
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
        
        # Ensure the contact has a phone_number set
        if contact_inbox.contact.phone_number.blank? && phone_number.present?
          formatted_phone = phone_number
          formatted_phone = "+#{formatted_phone}" unless formatted_phone.start_with?('+')
          contact_inbox.contact.update(phone_number: formatted_phone)
          Rails.logger.info("WHAPI updated contact phone_number to: #{formatted_phone}")
        end
        
        # Always update contact with WhatsApp profile information
        # Even if not in the webhook, we'll fetch it from the API
        update_contact_with_whatsapp_profile(contact_inbox.contact)
        
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
      message = find_message_by_source_id_or_content(message_id, status_data)
      
      if message.blank?
        # If this is for an outgoing message, try to find the conversation by phone number
        if is_outgoing && status_data[:to].present?
          Rails.logger.info("WHAPI attempting to find conversation for outgoing message to: #{status_data[:to]}")
          contact_inbox = inbox.contact_inboxes.where("source_id LIKE ?", "%#{status_data[:to]}%").first
          
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
        
        Rails.logger.info("WHAPI status update: no matching message found for #{message_id}")
        return
      end
      
      # Update message status
      Rails.logger.info("WHAPI updating message ##{message.id} status from #{message.status} to #{status}")
      
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
      Rails.logger.info("WHAPI updating contact profile for #{contact.id} (#{contact.name})")
      
      # First, check if we have profile data in the webhook
      contact_data = params[:contacts]&.first
      
      # If no contacts field, try to get info from the message
      if contact_data.blank? && params[:messages].present?
        message = params[:messages].first
        if message.present? && message[:from].present?
          # Create synthetic contact data from message
          contact_data = {
            profile: {
              name: message[:from_name]
            }
          }
          Rails.logger.info "WHAPI: Created synthetic contact data from message for #{message[:from]}"
        end
      end
      
      if contact_data.present?
        profile = contact_data[:profile] || {}
        
        # Update contact with profile data if available
        contact_update_params = {}
        
        # Name from profile
        if profile[:name].present?
          # Parse the full name to set first and last name
          name_parts = profile[:name].split(' ', 2)
          first_name = name_parts[0]
          last_name = name_parts.length > 1 ? name_parts[1] : nil
          
          # Store the full name in the name field (this is what displays in the UI)
          contact_update_params[:name] = profile[:name]
          
          # Also store the last name separately in the last_name field
          contact_update_params[:last_name] = last_name if last_name.present?
          
          Rails.logger.info "WHAPI parsing name from webhook: '#{profile[:name]}' → full name='#{profile[:name]}', last='#{last_name}'"
        end
        
        # Additional custom attributes from WhatsApp profile
        additional_attributes = contact.additional_attributes || {}
        
        if profile[:about].present?
          additional_attributes[:about] = profile[:about]
        end
        
        # Set profile image if available in webhook
        if profile[:profile_picture_url].present?
          additional_attributes[:profile_image] = profile[:profile_picture_url]
          
          # Schedule a job to download and set the profile image as avatar
          Rails.logger.info "WHAPI scheduling avatar update from webhook URL: #{profile[:profile_picture_url]}"
          Avatar::AvatarFromUrlJob.perform_later(contact, profile[:profile_picture_url])
          Rails.logger.info "WHAPI scheduled avatar update from webhook for contact: #{contact.id}"
        end
        
        # Save webhook data first
        # Only update additional_attributes if no other fields are being updated
        # to prevent overwriting previously set name values
        if contact_update_params.keys.any? { |k| k != :additional_attributes }
          # We have real contact data to update (like name, last_name)
          contact_update_params[:additional_attributes] = additional_attributes if additional_attributes.any?
        elsif additional_attributes.any?
          # We only have additional attributes, so don't risk overwriting existing contact data
          contact.update(additional_attributes: additional_attributes)
          Rails.logger.info "WHAPI updated contact additional attributes only: #{additional_attributes.inspect}"
          return
        end
        
        if contact_update_params.any?
          Rails.logger.info "WHAPI contact before webhook update - name: '#{contact.name}', last_name: '#{contact.last_name}'"
          contact.update(contact_update_params)
          Rails.logger.info "WHAPI updated contact from webhook data: #{contact_update_params.inspect}"
          Rails.logger.info "WHAPI contact after webhook update - name: '#{contact.name}', last_name: '#{contact.last_name}'"
        end
      end
      
      # Now fetch additional contact info and profile image via API
      # but only if we haven't done so recently (within 24 hours)
      if contact.additional_attributes['profile_updated_at'].present?
        last_update = Time.zone.parse(contact.additional_attributes['profile_updated_at']) rescue 30.days.ago
        if last_update > 24.hours.ago
          Rails.logger.info "WHAPI skipping API profile update - was updated at #{last_update}"
          return
        end
      end
      
      # Get WhatsApp channel's Whapi service
      whapi_service = inbox.channel.provider_service
      
      # Fetch additional contact info
      phone_number = contact.phone_number.presence || contact.identifier
      
      # Skip if no phone number is available
      unless phone_number.present?
        Rails.logger.info "WHAPI cannot update profile - no phone number available"
        return
      end
      
      # Fetch contact info from Whapi API
      Rails.logger.info "WHAPI fetching profile via API for #{phone_number}"
      contact_info = whapi_service.fetch_contact_info(phone_number)
      
      # Initialize attributes to update
      contact_update_params = {}
      additional_attributes = contact.additional_attributes || {}
      additional_attributes['profile_updated_at'] = Time.zone.now.to_s
      
      # Update with info from API response if available
      if contact_info.present?
        Rails.logger.info "WHAPI received contact info for #{phone_number}: #{contact_info.inspect}"
        
        # Use contact name from API if not already set
        if contact_info['name'].present? && (contact.name.blank? || contact.name == phone_number)
          # Parse the full name to set first and last name
          name_parts = contact_info['name'].split(' ', 2)
          first_name = name_parts[0]
          last_name = name_parts.length > 1 ? name_parts[1] : nil
          
          # Store the full name in the name field (this is what displays in the UI)
          contact_update_params[:name] = contact_info['name']
          
          # Also store the last name separately in the last_name field
          contact_update_params[:last_name] = last_name if last_name.present?
          
          Rails.logger.info "WHAPI parsing name from API: '#{contact_info['name']}' → full name='#{contact_info['name']}', last='#{last_name}'"
        end
        
        # Save business info if available
        if contact_info['business_profile'].present?
          additional_attributes['business_profile'] = contact_info['business_profile']
        end
        
        # Save status/about info if available
        if contact_info['status'].present?
          additional_attributes['about'] = contact_info['status']
        end
      end
      
      # Fetch profile image
      Rails.logger.info "WHAPI fetching profile image via API for #{phone_number}"
      profile_image = whapi_service.fetch_profile_image(phone_number)
      
      if profile_image.present? && profile_image['url'].present?
        Rails.logger.info "WHAPI received profile image URL: #{profile_image['url']}"
        additional_attributes['profile_image'] = profile_image['url']
        
        # Schedule a job to download and set the profile image as avatar
        Rails.logger.info "WHAPI scheduling avatar update from API URL: #{profile_image['url']}"
        Avatar::AvatarFromUrlJob.perform_later(contact, profile_image['url'])
        Rails.logger.info "WHAPI scheduled avatar update from API for contact: #{contact.id}"
      else
        Rails.logger.info "WHAPI no profile image found via API for #{phone_number}"
      end
      
      # Update the contact with all the new info
      # Only update additional_attributes if no other fields are being updated
      # to prevent overwriting previously set name values
      if contact_update_params.keys.any? { |k| k != :additional_attributes }
        # We have real contact data to update (like name, last_name)
        contact_update_params[:additional_attributes] = additional_attributes
      elsif additional_attributes.any?
        # We only have additional attributes, so don't risk overwriting existing contact data
        contact.update(additional_attributes: additional_attributes)
        Rails.logger.info "WHAPI updated contact additional attributes only: #{additional_attributes.inspect}"
        return
      end
      
      if contact_update_params.any?
        Rails.logger.info "WHAPI contact before API update - name: '#{contact.name}', last_name: '#{contact.last_name}'"
        contact.update(contact_update_params)
        Rails.logger.info "WHAPI updated contact from API: #{contact_update_params.inspect}"
        Rails.logger.info "WHAPI contact after API update - name: '#{contact.name}', last_name: '#{contact.last_name}'"
      end
      
      Rails.logger.info "Updated WhatsApp contact profile for #{contact.id}: #{phone_number}"
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
    
    # Helper to find a message by source_id or by content if source_id is not available
    def find_message_by_source_id_or_content(source_id, message_data)
      # First try to find by source_id
      message = Message.find_by(source_id: source_id)
      return message if message.present?
      
      # Check for success_timestamp format which is our fallback
      if source_id.to_s.include?("success_")
        Rails.logger.info("WHAPI trying to find message with a success_ fallback source_id")
        messages = Message.where("source_id LIKE ?", "success_%")
                         .where(message_type: :outgoing)
                         .order(created_at: :desc)
                         .limit(5)
        
        if messages.present?
          Rails.logger.info("WHAPI found #{messages.count} potential messages with success_ source_id")
          return messages.first # As a simple solution, take the most recent one
        end
      end
      
      # If not found by source_id, try to match by content and recency
      if message_data[:text] && message_data[:text][:body].present?
        content = message_data[:text][:body]
        
        Rails.logger.info("WHAPI trying to find message with content: #{content}")
        
        # Find conversations for the contact phone number
        chat_id = message_data[:chat_id]
        phone_number = chat_id.split('@').first
        
        contact_inboxes = inbox.contact_inboxes.where("source_id LIKE ?", "%#{phone_number}%")
        
        if contact_inboxes.present?
          # Find all conversations for these contact inboxes, safely
          conversation_ids = []
          contact_inboxes.each do |contact_inbox|
            conversations = Conversation.where(contact_inbox_id: contact_inbox.id)
            conversation_ids.concat(conversations.pluck(:id)) if conversations.any?
          end
          
          if conversation_ids.any?
            recent_messages = Message.where(conversation_id: conversation_ids)
                                    .where(message_type: :outgoing)
                                    .where(content: content)
                                    .or(Message.where("content LIKE ?", "%#{content}%")
                                          .where(conversation_id: conversation_ids))
                                    .where('created_at > ?', 1.hour.ago)
                                    .order(created_at: :desc)
                                    .limit(1)
            
            return recent_messages.first if recent_messages.present?
          end
        end
      end
      
      nil
    end
  end