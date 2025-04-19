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
        message = case message_type
        when 'text'
          create_text_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'image', 'video', 'audio', 'document'
          create_attachment_message(conversation, contact_inbox.contact, message_data, message_type, message_id, timestamp)
        when 'location'
          create_location_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'contact', 'contact_list'
          create_contact_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'interactive'
          create_interactive_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'button'
          create_button_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'sticker'
          create_sticker_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'voice'
          create_voice_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'reaction'
          create_reaction_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'poll'
          create_poll_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        when 'link_preview'
          create_link_preview_message(conversation, contact_inbox.contact, message_data, message_id, timestamp)
        else
          # Default handling for unsupported types
          Rails.logger.warn("WHAPI unsupported message type: #{message_type}")
          create_text_message(
            conversation, 
            contact_inbox.contact, 
            { text: { body: "Unsupported message type: #{message_type}" } }, 
            message_id, 
            timestamp
          )
        end
        
        Rails.logger.info("WHAPI created message of type #{message_type}: #{message&.id if message}")
        
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
      
      attachment_url = extract_media_url(media_data)
      media_id = media_data[:id]
      mime_type = determine_mime_type(media_data)
      caption = media_data[:caption] || ''
      
      # Get the API headers from the provider service
      api_headers = inbox.channel.provider_service.api_headers
      
      # Create a file from the URL
      begin
        attachment_file = download_attachment_with_retry(
          attachment_url,
          api_headers
        )
        
        # Use locale for messages
        I18n.with_locale(conversation.account.locale || 'en') do
          # Create the message with attachment
          message = conversation.messages.build(
            message_type: :incoming,
            sender: sender,
            source_id: message_id,
            created_at: timestamp,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            content: caption
          )
          
          filename = media_data[:file_name] || attachment_file.original_filename || "#{type}.#{mime_type.split('/').last}"
          
          Rails.logger.info("WHAPI attaching #{type} with file_type: #{mime_type}, filename: #{filename}")
          
          message.attachments.new(
            account_id: conversation.account_id,
            file_type: mime_type,
            file: {
              io: attachment_file,
              filename: filename,
              content_type: mime_type
            }
          )
          
          begin
            message.save!
            Rails.logger.info("WHAPI #{type} message saved successfully with ID: #{message.id}")
            message
          rescue => e
            Rails.logger.error("WHAPI failed to save #{type} message: #{e.message}")
            
            # Try again with a more generic MIME type if the specific one failed
            if mime_type.include?('/')
              fallback_mime_type = mime_type.split('/').first + '/mpeg'
              Rails.logger.info("WHAPI retrying with more generic MIME type: #{fallback_mime_type}")
              
              message.attachments.first.file_type = fallback_mime_type
              message.attachments.first.file.content_type = fallback_mime_type
              
              message.save!
              Rails.logger.info("WHAPI #{type} message saved successfully with fallback MIME type, ID: #{message.id}")
              message
            else
              # If that still fails, create a text message with the link instead
              Rails.logger.error("WHAPI could not save attachment, falling back to link")
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
        end
      rescue => e
        Rails.logger.error "Failed to download WHAPI attachment: #{e.message}"
        
        # Create a text message instead with link to the content
        I18n.with_locale(conversation.account.locale || 'en') do
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
      Rails.logger.info("WHAPI voice message data: #{message_data.inspect}")
      Rails.logger.info("WHAPI voice data field: #{voice_data.inspect}")
      return if voice_data.blank?
      
      # Get the API headers from the provider service
      api_headers = inbox.channel.provider_service.api_headers
      
      # Similar to audio message but marked as voice
      begin
        # Extract URL from multiple possible locations in the payload
        attachment_url = extract_media_url(voice_data)
        Rails.logger.info("WHAPI voice message URL: #{attachment_url}")
        
        if attachment_url.present?
          Rails.logger.info("WHAPI downloading voice message from: #{attachment_url}")
          
          attachment_file = nil
          download_error = nil
          
          # First try: Use our retry helper to download the file
          begin
            attachment_file = download_attachment_with_retry(attachment_url, api_headers)
            Rails.logger.info("WHAPI voice message downloaded successfully, size: #{attachment_file.size} bytes")
          rescue => e
            download_error = e
            Rails.logger.error("WHAPI primary download method failed: #{e.message}")
            
            # Second try: Use HTTParty as a fallback
            begin
              Rails.logger.info("WHAPI trying fallback download method with HTTParty")
              temp_file = Tempfile.new(['voice_message', '.ogg'])
              
              response = HTTParty.get(attachment_url, headers: api_headers)
              if response.success?
                temp_file.binmode
                temp_file.write(response.body)
                temp_file.rewind
                
                attachment_file = temp_file
                Rails.logger.info("WHAPI fallback download succeeded, size: #{temp_file.size} bytes")
              else
                Rails.logger.error("WHAPI fallback download failed with status: #{response.code}")
                raise "HTTParty download failed with status: #{response.code}"
              end
            rescue => e2
              Rails.logger.error("WHAPI fallback download failed: #{e2.message}")
              # Re-raise the original error
              raise download_error
            end
          end
          
          if attachment_file.present?
            # Now set the locale for translations
            I18n.with_locale(conversation.account.locale || 'en') do

              # Create the message with voice as an attachment
              message = conversation.messages.build(
                message_type: :incoming,
                sender: sender,
                source_id: message_id,
                created_at: timestamp,
                account_id: conversation.account_id,
                inbox_id: conversation.inbox_id,
                content: I18n.t('whatsapp.voice_message') # Use localized message
              )
              
              # Determine proper MIME type for WhatsApp voice messages
              # WhatsApp typically uses audio/ogg with opus codec
              mime_type = determine_mime_type(voice_data, attachment_file)
              Rails.logger.info("WHAPI voice message mime type: #{mime_type}")
              
              # Get filename from payload or generate a reasonable one
              filename = voice_data[:file_name] || voice_data[:filename] || "voice_message_#{Time.now.to_i}.ogg"
              
              # Store the original MIME type for reference
              attachment_attributes = {
                account_id: conversation.account_id,
                file_type: :audio, # Use the enum symbol
                file: {
                  io: attachment_file,
                  filename: filename,
                  content_type: mime_type # Keep original mime type for file content
                }
              }

              message.attachments.new(attachment_attributes)
              
              # Log everything before saving for debugging
              Rails.logger.info("WHAPI attaching voice with file_type: :audio, filename: #{filename}, original_mime_type: #{mime_type}")
              
              begin
                message.save!
                Rails.logger.info("WHAPI voice message saved successfully with ID: #{message.id}")
                message
              rescue => e
                Rails.logger.error("WHAPI failed to save voice message: #{e.message}")
                Rails.logger.error(e.backtrace.join("\n"))
                
                # Try again with a more generic MIME type if the specific one failed
                if mime_type.include?('/')
                  fallback_mime_type = mime_type.split('/').first + '/mpeg'
                  Rails.logger.info("WHAPI retrying with more generic MIME type: #{fallback_mime_type}")
                  
                  message.attachments.first.file_type = fallback_mime_type
                  message.attachments.first.file.content_type = fallback_mime_type
                  
                  message.save!
                  Rails.logger.info("WHAPI voice message saved successfully with fallback MIME type, ID: #{message.id}")
                  message
                else
                  raise e
                end
              end
            end
          else
            raise "Failed to download voice message after multiple attempts"
          end
        else
          Rails.logger.warn("WHAPI voice message URL not found in payload")
          I18n.with_locale(conversation.account.locale || 'en') do
            conversation.messages.create!(
              content: I18n.t('whatsapp.voice_message_url_not_available'),
              message_type: :incoming,
              sender: sender,
              source_id: message_id,
              created_at: timestamp,
              account_id: conversation.account_id,
              inbox_id: conversation.inbox_id
            )
          end
        end
      rescue => e
        Rails.logger.error "WHAPI Entered rescue block in create_voice_message for message_id: #{message_id}"
        Rails.logger.error("WHAPI Error details: #{e.message}")
        create_error_audio_message(conversation, sender, message_id, timestamp, I18n.t('whatsapp.voice_message_download_failed'))
      end
    end
    
    # Helper method to create an audio attachment message indicating an error
    def create_error_audio_message(conversation, sender, message_id, timestamp, error_content)
      # <<< DETAILED LOCALE LOGGING - START >>>
      account_locale = conversation&.account&.locale || 'account_locale_missing'
      Rails.logger.info("WHAPI create_error_audio_message: Account locale determined as: #{account_locale}")
      target_locale = account_locale == 'account_locale_missing' ? 'en' : account_locale
      Rails.logger.info("WHAPI create_error_audio_message: Target locale for I18n.with_locale: #{target_locale}")
      # <<< DETAILED LOCALE LOGGING - END >>>

      I18n.with_locale(target_locale) do
        # <<< DETAILED LOCALE LOGGING - START >>>
        current_i18n_locale = I18n.locale
        Rails.logger.info("WHAPI create_error_audio_message: Locale INSIDE I18n.with_locale block: #{current_i18n_locale}")
        translated_content = I18n.t('whatsapp.voice_message_download_failed')
        Rails.logger.info("WHAPI create_error_audio_message: Result of I18n.t: '#{translated_content}'")
        # Ensure we use the potentially translated content, not the passed English one
        # error_content = translated_content # <-- We actually want the translated one IF locale worked
        # <<< DETAILED LOCALE LOGGING - END >>>

        message = conversation.messages.build(
          message_type: :incoming,
          sender: sender,
          source_id: message_id,
          created_at: timestamp,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          content: translated_content # Use the translated content here
        )
        
        # <<< DETAILED LOCALE LOGGING - START >>>
        Rails.logger.info("WHAPI create_error_audio_message: Message object content before save: '#{message.content}'")
        # <<< DETAILED LOCALE LOGGING - END >>>

        # Create a dummy attachment of type audio
        # The frontend will use the message content to show the warning
        message.attachments.new(
          account_id: conversation.account_id,
          file_type: :audio 
        )
        
        message.save!
        Rails.logger.info("WHAPI created error audio message for #{message_id}")
        message
      end
    end
    
    # Helper method to extract media URL from various possible locations in Whapi payload
    def extract_media_url(media_data)
      return nil if media_data.blank?
      
      # Try all possible keys where URL might be stored
      url = media_data[:url] ||
            media_data[:link] ||
            media_data[:media_url] ||
            media_data[:media_link] ||
            media_data[:file_url] ||
            media_data[:download_url] ||
            media_data[:media]
            
      Rails.logger.info("WHAPI extracted media URL: #{url}")
      
      # Ensure URL is valid
      begin
        uri = URI.parse(url) if url.present?
        return url if uri&.scheme&.in?(%w[http https])
      rescue URI::InvalidURIError => e
        Rails.logger.error("WHAPI invalid media URL: #{e.message}")
      end
      
      # If no valid URL found, try to use media_id to get URL from Whapi API
      if media_data[:id].present?
        Rails.logger.info("WHAPI no valid URL found, using media ID: #{media_data[:id]}")
        return get_media_url_from_id(media_data[:id])
      end
      
      nil
    end
    
    # Try to get media URL using Whapi's media endpoint
    def get_media_url_from_id(media_id)
      begin
        api_headers = inbox.channel.provider_service.api_headers
        api_base_url = inbox.channel.provider_service.api_base_url
        
        media_url = "#{api_base_url}/media/#{media_id}"
        Rails.logger.info("WHAPI constructed media URL: #{media_url}")
        return media_url
      rescue => e
        Rails.logger.error("WHAPI failed to get media URL from ID: #{e.message}")
        return nil
      end
    end
    
    # Download attachment with retries
    def download_attachment_with_retry(url, headers, max_retries = 3)
      attempts = 0
      last_error = nil
      
      while attempts < max_retries
        begin
          # Attempt to download with timeout
          return Timeout.timeout(20) do
            Down.download(
              url, 
              headers: headers,
              # The Down gem 5.4.0 doesn't support many options
              # Keep it minimal
              max_size: 50 * 1024 * 1024 # 50MB max size for voice messages
            )
          end
        rescue Down::TimeoutError, Timeout::Error => e
          attempts += 1
          last_error = e
          wait_time = 2 ** attempts # Exponential backoff
          Rails.logger.error("WHAPI download attempt #{attempts} failed with timeout after #{wait_time}s: #{e.message}")
          sleep(wait_time) if attempts < max_retries
        rescue Down::ServerError, Down::ConnectionError => e
          attempts += 1
          last_error = e
          wait_time = 2 ** attempts # Exponential backoff
          Rails.logger.error("WHAPI download attempt #{attempts} failed with server error after #{wait_time}s: #{e.message}")
          sleep(wait_time) if attempts < max_retries
        rescue => e
          # For any other error, retry once then give up
          attempts += 1
          last_error = e
          Rails.logger.error("WHAPI download attempt #{attempts} failed with error: #{e.message}")
          sleep(2) if attempts < 2
          break if attempts >= 2
        end
      end
      
      # If we get here, all retries failed
      raise last_error || StandardError.new("Download failed after #{max_retries} attempts")
    end
    
    # Helper method to determine the proper MIME type for voice messages
    def determine_mime_type(media_data, file = nil)
      # First try to get mime type from the payload
      mime_type = media_data[:mime_type] || 
                 media_data[:mimetype] || 
                 media_data[:content_type]
                 
      # If no mime type in payload, try to detect from file if available
      if mime_type.blank? && file.present?
        require 'marcel'
        detected_type = Marcel::MimeType.for(file)
        mime_type = detected_type if detected_type.present?
      end
                 
      # Default to audio/ogg for WhatsApp voice messages if still blank
      mime_type = mime_type.presence || 'audio/ogg'
      
      # Clean up the mime type - Chatwoot only allows simple MIME types without parameters
      # So "audio/ogg; codecs=opus" becomes just "audio/ogg"
      if mime_type.include?(';')
        base_mime_type = mime_type.split(';').first.strip
        Rails.logger.info("WHAPI simplified MIME type from #{mime_type} to #{base_mime_type}")
        return base_mime_type
      end
      
      mime_type
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