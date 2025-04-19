class Whatsapp::IncomingMessageWhapiService
    pattr_initialize [:inbox!, :params!]
    
    # How often to re-check for profile updates (e.g., 24 hours)
    PROFILE_REFETCH_THRESHOLD = 24.hours
    
    def perform
      Rails.logger.info("WHAPI Service starting to process webhook: #{inbox.id}")
      Rails.logger.info("WHAPI webhook payload: #{params.inspect}")
      
      # Process different types of events from Whapi webhooks
      if message_event?
        process_messages
      elsif status_event?
        process_status_update
      elsif !message_event? && !status_event? # Log if we can't process the event
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
    
    def process_messages
      # Process each message in the payload
      params[:messages]&.each do |message_data|
        Rails.logger.info("WHAPI processing message: #{message_data.inspect}")

        if outgoing_message?(message_data)
          process_outgoing_message(message_data)
        else
          process_incoming_message(message_data)
        end
      end
    end
    
    def process_status_update
      # Process delivery and read receipts from STATUS webhooks
      status_data = params[:status]
      return if status_data.blank?
      
      Rails.logger.info("WHAPI processing status update: #{status_data.inspect}")

      message_id = status_data[:id]
      status_code = status_data[:status] # e.g., 'sent', 'delivered', 'read', 'failed'

      # Map Whapi status codes to Chatwoot statuses if necessary
      chatwoot_status = case status_code
                        when 'sent' then :sent
                        when 'delivered' then :delivered
                        when 'read' then :read
                        when 'failed' then :failed # Add handling for failed status
                        else
                          Rails.logger.warn("WHAPI unknown status code: #{status_code}")
                          nil
                        end

      # Find the message by its source_id (the Whapi message ID)
      message = Message.find_by(source_id: message_id)

      if message.present? && chatwoot_status.present?
        # Avoid overwriting later statuses with earlier ones (e.g., 'sent' after 'delivered')
        current_status_index = Message.statuses[message.status]
        new_status_index = Message.statuses[chatwoot_status.to_s]

        if new_status_index > current_status_index
          Rails.logger.info("WHAPI updating message #{message.id} status from #{message.status} to #{chatwoot_status}")
          message.update!(status: chatwoot_status)
        else
          Rails.logger.info("WHAPI skipping status update for message #{message.id}: current status '#{message.status}' is later than or equal to new status '#{chatwoot_status}'")
        end
      elsif message.blank?
        Rails.logger.warn("WHAPI could not find message with source_id: #{message_id} for status update.")
      end
    rescue StandardError => e
      Rails.logger.error("WHAPI status update processing error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\\n"))
    end
    
    def process_incoming_message(message_data)
      phone_number = message_data[:from]
      message_id = message_data[:id]
      message_type = message_data[:type]
      timestamp = Time.at(message_data[:timestamp].to_i)

      Rails.logger.info("WHAPI processing incoming message - phone: #{phone_number}, msg_id: #{message_id}, type: #{message_type}")

      contact_inbox, conversation = find_or_create_contact_and_conversation(phone_number)
      return unless contact_inbox && conversation

      # Check if message already exists
      if conversation.messages.where(source_id: message_id).exists?
        Rails.logger.info("WHAPI incoming message already exists, skipping: #{message_id}")
        return
      end

      # Delegate to type-specific handler
      handle_incoming_message_type(conversation, contact_inbox.contact, message_data, message_id, timestamp)

    rescue StandardError => e
      Rails.logger.error("WHAPI incoming message processing error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\\n"))
    end
    
    def handle_incoming_message_type(conversation, sender, message_data, message_id, timestamp)
      message_type = message_data[:type]
      message = case message_type
                when 'text'
                  create_text_message(conversation, sender, message_data, message_id, timestamp)
                when 'image', 'video', 'audio', 'document'
                  create_attachment_message(conversation, sender, message_data, message_type, message_id, timestamp)
                when 'location'
                  create_location_message(conversation, sender, message_data, message_id, timestamp)
                when 'contact', 'contact_list'
                  create_contact_message(conversation, sender, message_data, message_id, timestamp)
                when 'interactive'
                  create_interactive_message(conversation, sender, message_data, message_id, timestamp)
                when 'button'
                  create_button_message(conversation, sender, message_data, message_id, timestamp)
                when 'sticker'
                  create_sticker_message(conversation, sender, message_data, message_id, timestamp)
                when 'voice'
                  create_voice_message(conversation, sender, message_data, message_id, timestamp)
                when 'reaction'
                  create_reaction_message(conversation, sender, message_data, message_id, timestamp)
                when 'poll'
                  create_poll_message(conversation, sender, message_data, message_id, timestamp)
                when 'link_preview'
                  create_link_preview_message(conversation, sender, message_data, message_id, timestamp)
                else
                  Rails.logger.warn("WHAPI unsupported incoming message type: #{message_type}")
                  nil # Or create a placeholder?
                end

      Rails.logger.info("WHAPI created incoming message ##{message.id}") if message&.persisted?
    end
    
    def process_outgoing_message(message_data)
      message_id = message_data[:id]
      Rails.logger.info("WHAPI processing outgoing message update/creation: #{message_id}")

      # Try to find the message in our system by source_id or content (if sent via Chatwoot API)
      existing_message = find_message_by_source_id_or_content(message_id, message_data)

      if existing_message.present?
        handle_existing_outgoing_message_update(existing_message, message_data)
      else
        handle_new_outgoing_message_creation(message_data)
      end
    rescue StandardError => e
      Rails.logger.error("WHAPI outgoing message processing error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\\n"))
    end
    
    def handle_existing_outgoing_message_update(existing_message, message_data)
      Rails.logger.info("WHAPI found existing outgoing message #{existing_message.id}, updating status/source_id")
      message_id = message_data[:id]
      new_status = message_data[:status]
      valid_statuses = Message.statuses.keys # Get valid enum keys

      update_attrs = {}
      update_attrs[:source_id] = message_id if existing_message.source_id != message_id
      
      # Only update status if the new status is valid and different from current
      if new_status.present? && valid_statuses.include?(new_status) && existing_message.status != new_status
        update_attrs[:status] = new_status
        Rails.logger.info("WHAPI Updating status to valid value: #{new_status}")
      elsif new_status.present? && !valid_statuses.include?(new_status)
        Rails.logger.warn("WHAPI Received invalid status '#{new_status}' for message #{existing_message.id}. Ignoring status update.")
      end

      existing_message.update(update_attrs) if update_attrs.present?
    end
    
    def handle_new_outgoing_message_creation(message_data)
      message_id = message_data[:id]
      Rails.logger.info("WHAPI creating new outgoing message from webhook: #{message_id}")

      # Extract recipient info
      recipient_phone_number = message_data[:to] || message_data[:chat_id]&.split('@')&.first
      if recipient_phone_number.blank?
        Rails.logger.error("WHAPI cannot process outgoing message: recipient phone number not found: #{message_data.inspect}")
        return
      end
      recipient_phone_number = "+#{recipient_phone_number}" unless recipient_phone_number.start_with?('+')

      message_type = message_data[:type]
      timestamp = Time.at(message_data[:timestamp].to_i)
      Rails.logger.info("WHAPI outgoing message details - recipient: #{recipient_phone_number}, msg_id: #{message_id}, type: #{message_type}")

      # Find or create contact/conversation for the RECIPIENT
      contact_inbox, conversation = find_or_create_contact_and_conversation(recipient_phone_number, :recipient)
      return unless contact_inbox && conversation

      # Check if this specific outgoing message already exists (e.g., due to retry)
      if conversation.messages.where(source_id: message_id).exists?
        Rails.logger.info("WHAPI outgoing message already exists, skipping creation: #{message_id}")
        return
      end

      # Delegate to type-specific handler, ensuring message_type is :outgoing
      handle_outgoing_message_type(conversation, message_data, message_id, timestamp)
    end
    
    def handle_outgoing_message_type(conversation, message_data, message_id, timestamp)
      message_type = message_data[:type]
      # Sender is nil for outgoing messages created from webhooks
      sender = nil
      # Explicitly set Chatwoot message_type enum to :outgoing
      chatwoot_message_type = :outgoing

      message = case message_type
                when 'text'
                  create_text_message(conversation, sender, message_data, message_id, timestamp, chatwoot_message_type)
                when 'image', 'video', 'audio', 'document', 'sticker', 'voice'
                  # Note: We might create placeholders for some types like stickers if download fails/is skipped
                  create_attachment_message(conversation, sender, message_data, message_type, message_id, timestamp, chatwoot_message_type)
                when 'location'
                  create_location_message(conversation, sender, message_data, message_id, timestamp, chatwoot_message_type)
                # Add other types as needed (location, contact, interactive, etc.)
                else
                  Rails.logger.warn("WHAPI unsupported outgoing message type: #{message_type}")
                  # Create a generic text placeholder?
                  create_text_message(conversation, sender, { text: { body: "[Unsupported Outgoing Message Type: #{message_type}]" } }, message_id, timestamp, chatwoot_message_type)
                end

      if message&.persisted?
        Rails.logger.info("WHAPI created outgoing message ##{message.id} of type #{message_type}")
      else
        Rails.logger.warn("WHAPI failed to create outgoing message for type #{message_type}")
      end
    end
    
    def find_or_create_contact_and_conversation(phone_number, direction = :incoming)
      # Get provider service to use helper methods
      provider_service = inbox.channel.provider_service

      # Format number - ensure '+' prefix
      formatted_phone = phone_number
      formatted_phone = "+#{formatted_phone}" unless formatted_phone.start_with?('+')

      # Use cleaned number (digits only) for source_id, full number for contact attribute
      id_formats = provider_service.format_whatsapp_id(formatted_phone)
      contact_source_id = id_formats[:clean] # Typically digits only for source_id
      contact_phone_attribute = id_formats[:original] # Typically number with '+' for display/attribute

      Rails.logger.info("WHAPI formatted IDs for #{direction} contact: source_id=#{contact_source_id}, phone_attribute=#{contact_phone_attribute}")

      # Fetch profile name from API if possible
      profile_name = contact_name(contact_phone_attribute) || contact_phone_attribute

      # Find or create ContactInbox and Contact
      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: contact_source_id,
        inbox: inbox,
        contact_attributes: {
          name: profile_name,
          phone_number: contact_phone_attribute # Ensure full number is set on Contact
        }
      ).perform

      # Ensure contact phone number is correctly set/updated
      contact = contact_inbox.contact
      if contact.phone_number != contact_phone_attribute
        contact.update!(phone_number: contact_phone_attribute)
        Rails.logger.info("WHAPI ensured contact phone_number updated to: #{contact_phone_attribute}")
      end

      # For incoming messages, always try to update profile details from API
      update_contact_with_whatsapp_profile(contact) if direction == :incoming

      Rails.logger.info("WHAPI found/created contact_inbox: #{contact_inbox.id} for contact: #{contact.id}")

      # Find or create conversation
      conversation = ::Conversation.create_with(
        account_id: inbox.account_id,
        contact_id: contact.id,
        status: :open
      ).find_or_create_by!(
        inbox_id: inbox.id,
        contact_inbox_id: contact_inbox.id
      ) { |conv| Rails.logger.info("WHAPI creating new conversation for contact: #{contact.id}") }

      Rails.logger.info("WHAPI found/created conversation #{conversation.id}")

      return contact_inbox, conversation

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("WHAPI failed to create/update contact/conversation: #{e.message} - #{e.record.errors.full_messages.join(', ')}")
      return nil, nil
    rescue StandardError => e
      Rails.logger.error("WHAPI error finding/creating contact/conversation: #{e.message}")
      Rails.logger.error(e.backtrace.join("\\n"))
      return nil, nil
    end
    
    def create_text_message(conversation, sender, message_data, message_id, timestamp, message_type = :incoming)
      # Handle quoted messages if present
      quoted_message_details = extract_quoted_message_details(message_data[:context])
      content = message_data.dig(:text, :body) || ''

      message = conversation.messages.build(
        content: content,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: message_type, # Use passed message_type
        sender: sender, # Will be nil for outgoing messages from webhook
        source_id: message_id,
        status: message_data[:status] || (message_type == :outgoing ? :sent : :sent), # Use :sent for incoming
        created_at: timestamp,
        content_attributes: quoted_message_details # Add quoted info here
      )
      message.save!
      message
    end
    
    def create_attachment_message(conversation, sender, message_data, type, message_id, timestamp, message_type = :incoming)
      # Normalize type for different attachment kinds
      internal_type = case type
                      when 'image', 'sticker' then 'image' # Treat stickers as images for attachment type
                      when 'video' then 'video'
                      when 'audio', 'voice' then 'audio' # Treat voice notes as audio
                      when 'document' then 'file'
                      else 'file' # Default to file
                      end

      media_data = message_data[type.to_sym] # Use the original type key ('image', 'sticker', 'video', etc.)
      caption = message_data[:caption] || '' # Images/Videos/Docs can have captions

      # Special handling for outgoing stickers - create placeholder as download is skipped/fails
      if type == 'sticker' && message_type == :outgoing
        Rails.logger.info("WHAPI handling outgoing sticker message, skipping download.")
        return create_text_message(conversation, sender, { text: { body: "[Sticker]" } }, message_id, timestamp, message_type)
        # Alternatively, could create an Attachment record without a file if needed later
      end

      # --- Download logic ---
      media_url = extract_media_url(media_data)
      downloaded_file = nil
      error_content = nil

      if media_url.present?
        begin
          # Use helper method to download the file
          Rails.logger.info("WHAPI attempting download from URL: #{media_url}")
          downloaded_file = download_file(media_url)
          Rails.logger.info("WHAPI successfully downloaded file for message #{message_id}") if downloaded_file
        rescue StandardError => e
          Rails.logger.error("WHAPI download failed for #{type} from #{media_url}: #{e.message}")
          error_content = I18n.t('errors.whatsapp.media_download_failed', type: type)
          # For incoming messages, create an error placeholder instead of failing
          if message_type == :incoming
            return create_error_message_for_attachment(conversation, sender, message_id, timestamp, caption, internal_type, message_type)
          else
            # For outgoing, maybe still create placeholder? Or just log?
            Rails.logger.error("WHAPI Failed to download media for outgoing message #{message_id}, type #{type}. Skipping attachment creation.")
            # Optionally create a text message placeholder for outgoing errors too
            return create_text_message(conversation, sender, { text: { body: "[Failed to process outgoing #{type}] #{caption}".strip } }, message_id, timestamp, message_type)
          end
        end
      elsif message_type == :incoming # Only error if URL is missing for incoming that *should* have one
        Rails.logger.error("WHAPI media URL missing for incoming #{type} message: #{message_data.inspect}")
        error_content = I18n.t('errors.whatsapp.media_url_missing', type: type)
        return create_error_message_for_attachment(conversation, sender, message_id, timestamp, caption, internal_type, message_type)
      else
        # For outgoing messages without a URL (e.g., maybe some types don't provide one in webhook immediately)
        Rails.logger.warn("WHAPI media URL missing for outgoing #{type} message webhook: #{message_data.inspect}. Creating placeholder.")
        # Create a text placeholder for outgoing message without media URL
        return create_text_message(conversation, sender, { text: { body: "[Outgoing #{type}] #{caption}".strip } }, message_id, timestamp, message_type)
      end

      return nil unless downloaded_file # Should have returned earlier if download failed/skipped

      # --- Message and Attachment Creation ---
      message = conversation.messages.build(
        content: caption, # Use caption as content
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: message_type,
        sender: sender,
        source_id: message_id,
        status: message_data[:status] || (message_type == :outgoing ? :sent : :sent), # Use :sent for incoming
        created_at: timestamp
        # Add quoted message details if needed
        # content_attributes: extract_quoted_message_details(message_data[:context])
      )

      # Determine mime type and filename
      mime_type = determine_mime_type(media_data, downloaded_file)
      original_filename = media_data[:filename] || media_data[:caption] || extract_filename_from_url(media_url) || "#{type}_#{message_id}"
      # Ensure filename has an extension based on mime type if missing
      extension = Marcel::MimeType.for(mime_type)&.split('/')&.last
      original_filename += ".#{extension}" if extension && !original_filename.include?('.')


      attachment = message.attachments.build(
        account_id: conversation.account_id,
        file_type: internal_type,
        file: {
          io: downloaded_file,
          filename: original_filename,
          content_type: mime_type
        }
      )
      # Add dimensions for images/videos if available
      if ['image', 'video'].include?(internal_type) && media_data.key?(:width) && media_data.key?(:height)
          attachment.metadata = { width: media_data[:width], height: media_data[:height] }
      end


      message.save!
      downloaded_file.close # Close the tempfile after saving
      message
    end
    
    def create_location_message(conversation, sender, message_data, message_id, timestamp, message_type = :incoming)
      location_data = message_data[:location]
      return unless location_data

      lat = location_data[:latitude]
      long = location_data[:longitude]
      address = location_data[:address] || location_data[:name] # Use name if address is missing
      label = address || "" # Fallback label
      map_link = "https://www.google.com/maps/search/?api=1&query=#{lat},#{long}"

      # Create a simple text message, the location details are in the attachment
      message = conversation.messages.build(
        content: label, # Use label or address as basic content
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: message_type, # Use the passed message_type
        sender: sender,
        source_id: message_id,
        status: :sent,
        created_at: timestamp,
        content_type: :text # Keep base message as text, attachment handles location type
      )

      # Build the location attachment
      attachment = message.attachments.build(
        account_id: conversation.account_id,
        file_type: :location,
        external_url: map_link,
        coordinates_lat: lat,
        coordinates_long: long,
        fallback_title: label,
        metadata: {
          coordinatesLat: lat,
          coordinatesLong: long,
          name: location_data[:name], # Store name from payload
          address: address # Store address
        }
      )

      message.save!
      message
    end
    
    def create_contact_message(conversation, sender, message_data, message_id, timestamp)
      # Whapi might send single 'contact' or array 'contact_list'
      contact_data = message_data[:contact] || message_data[:contact_list]
      return unless contact_data

      contacts_to_process = contact_data.is_a?(Array) ? contact_data : [contact_data]
      content_lines = []
      contacts_attributes = []

      contacts_to_process.each do |contact_info|
        vcard = contact_info[:vcard]
        next unless vcard

        # Basic parsing - can be improved with a vcard library
        name = vcard.match(/FN:(.+)/i)&.captures&.first&.strip
        org = vcard.match(/ORG:(.+)/i)&.captures&.first&.strip
        tel = vcard.match(/TEL(?:;.+?):(.+)/i)&.captures&.first&.strip

        line = "Contact: #{name}"
        line += " (#{org})" if org.present?
        line += " - #{tel}" if tel.present?
        content_lines << line

        contacts_attributes << {
          name: name,
          phone_number: tel,
          vcard: vcard # Store raw vcard
        }
      end

      message = conversation.messages.build(
        content: content_lines.join("\n"),
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        status: :sent, # Use :sent for incoming
        created_at: timestamp,
        content_type: 'contact', # Custom content type
        content_attributes: { contacts: contacts_attributes }
      )
      message.save!
      message
    end
    
    def create_interactive_message(conversation, sender, message_data, message_id, timestamp)
      interactive_data = message_data[:interactive]
      return unless interactive_data

      content = ''
      submitted_id = nil
      interactive_type = interactive_data[:type]

      case interactive_type
      when 'button_reply'
        content = interactive_data.dig(:button_reply, :title) || 'Button Clicked'
        submitted_id = interactive_data.dig(:button_reply, :id)
      when 'list_reply'
        content = interactive_data.dig(:list_reply, :title) || 'List Item Selected'
        content += ": #{interactive_data.dig(:list_reply, :description)}" if interactive_data.dig(:list_reply, :description)
        submitted_id = interactive_data.dig(:list_reply, :id)
      # Add other interactive types if needed (e.g., product)
      else
        content = "[Interactive Message: #{interactive_type}]"
      end

      message = conversation.messages.build(
        content: content,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :incoming,
        sender: sender,
        source_id: message_id,
        status: :sent, # Use :sent for incoming
        created_at: timestamp,
        content_type: 'interactive', # Custom content type
        content_attributes: {
                               interactive_type: interactive_type,
                               submitted_id: submitted_id,
                               # Include original payload for reference?
                               # raw_interactive_data: interactive_data
                             }
      )
      message.save!
      message
    end
    
    def create_button_message(conversation, sender, message_data, message_id, timestamp)
      # This seems to be for the *reply* to a button message, handled by interactive?
      # If Whapi sends a specific type for *sending* button messages, handle here.
      # Assuming this is redundant with 'interactive' type for now.
      Rails.logger.warn("WHAPI Received 'button' type message - likely handled by 'interactive'. Payload: #{message_data.inspect}")
      # Fallback to text or interactive handler?
      create_interactive_message(conversation, sender, message_data, message_id, timestamp)
    end
    
    def create_sticker_message(conversation, sender, message_data, message_id, timestamp)
      # Stickers are handled by create_attachment_message now, treating them as 'image' file_type
      # This method is kept for clarity but delegates
      create_attachment_message(conversation, sender, message_data, 'sticker', message_id, timestamp)
    end
    
    def create_voice_message(conversation, sender, message_data, message_id, timestamp)
      # Voice messages are handled by create_attachment_message now, treating them as 'audio' file_type
      # This method is kept for clarity but delegates
      create_attachment_message(conversation, sender, message_data, 'voice', message_id, timestamp)
    end
    
    def create_reaction_message(conversation, sender, message_data, message_id, timestamp)
      action_data = message_data[:action] || message_data[:reaction] # Use :reaction if present
      return unless action_data

      emoji = action_data[:emoji]
      reacted_message_id = action_data[:message_id]

      content = "Reacted #{emoji} to message #{reacted_message_id}"

      # Find the message being reacted to
      reacted_message = conversation.messages.find_by(source_id: reacted_message_id)

      message = conversation.messages.build(
        content: content,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :incoming, # Reactions are typically incoming
        sender: sender,
        source_id: message_id, # ID of the reaction message itself
        status: :sent, # Use :sent for incoming
        created_at: timestamp,
        content_type: 'reaction', # Custom content type
        content_attributes: {
                               emoji: emoji,
                               reacted_message_source_id: reacted_message_id,
                               # Store chatwoot ID if found
                               reacted_message_id: reacted_message&.id
                             }
      )
      message.save!

      # Potentially update the original message's metadata too?
      if reacted_message
        reactions = reacted_message.additional_attributes['reactions'] || {}
        reactions[sender.id.to_s] = emoji # Store reaction by sender ID
        reacted_message.update!(additional_attributes: reacted_message.additional_attributes.merge('reactions' => reactions))
      end

      message
    end
    
    def create_poll_message(conversation, sender, message_data, message_id, timestamp)
      poll_data = message_data[:poll]
      return unless poll_data
      
      # This might be a poll *creation* or a poll *update/vote*
      # For simplicity, let's just log the creation/update for now
      # A full implementation would require Poll models & tracking votes

      title = poll_data[:title]
      options = poll_data[:options] # Array of { name: 'Option 1', local_id: 1 }
      # Votes might be in poll_data[:results] or similar? Check Whapi docs.

      content = "Poll: #{title}\n"
      content += options.map { |opt| "- #{opt[:name]}" }.join("\n")

      message = conversation.messages.build(
        content: content,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :incoming, # Assume incoming for now
        sender: sender,
        source_id: message_id,
        status: :sent, # Use :sent for incoming
        created_at: timestamp,
        content_type: 'poll', # Custom content type
        content_attributes: {
                               title: title,
                               options: options # Store options
                               # Add vote data if available
                             }
      )
      message.save!
      message
    end
    
    def create_link_preview_message(conversation, sender, message_data, message_id, timestamp)
      # Link previews are often attached to text messages.
      # This might just be additional metadata on a text message webhook.
      # Check if message_data also contains a :text field.
      text_content = message_data.dig(:text, :body)
      link_data = message_data[:link_preview]

      if text_content.present? && link_data.present?
        Rails.logger.info("WHAPI Received link preview with text message: #{message_id}")
        # Create the text message and add link preview data to content_attributes
        message = create_text_message(conversation, sender, message_data, message_id, timestamp)
        message.update!(content_attributes: message.content_attributes.merge(link_preview: link_data)) if message
        return message
      elsif link_data.present?
        # Handle standalone link preview? Unlikely, but possible.
        Rails.logger.warn("WHAPI Received standalone link preview message? #{message_data.inspect}")
        content = link_data[:url] || link_data[:title] || "[Link Preview]"
        message = conversation.messages.build(
          content: content,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :incoming,
          sender: sender,
          source_id: message_id,
          status: :sent, # Use :sent for incoming
          created_at: timestamp,
          content_type: 'text', # Treat as text?
          content_attributes: { link_preview: link_data }
        )
        message.save!
        return message
      else
        Rails.logger.error("WHAPI Invalid link preview message data: #{message_data.inspect}")
        return nil
      end
    end
    
    def create_error_message_for_attachment(conversation, sender, message_id, timestamp, caption, type, message_type)
      # Construct error message content using I18n
      error_content = I18n.t(
        'errors.whatsapp.media_handling_error',
        type: type.capitalize,
        caption: caption.present? ? " with caption \"#{caption}\"" : ""
      )

      Rails.logger.info("WHAPI Creating error placeholder message for failed #{type} attachment: #{message_id}")

      message = conversation.messages.build(
        content: error_content.strip,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: message_type, # incoming or outgoing
        sender: sender,
        source_id: message_id,
        status: message_type == :outgoing ? :failed : :sent, # Use :sent for incoming errors
        created_at: timestamp,
        private: true # Make it private so only agents see the error? Optional.
      )
      message.save!
      message
    end
    
    def download_file(url)
      # Reuse existing logic or implement download with retry/error handling
      # Example using open-uri and Down:
      require 'down'

      tempfile = Down.download(
        url,
        max_size: 100 * 1024 * 1024, # 100 MB limit - adjust as needed
        headers: { 'Authorization' => "Bearer #{inbox.channel.provider_config['api_key']}" } # Add auth if needed by Whapi media URL
        # Add other headers if required
      )
      Rails.logger.info "WHAPI Download successful, tempfile size: #{tempfile.size}"
      tempfile # Return the tempfile object
    rescue Down::Error => e # Catch specific Down errors
      Rails.logger.error "WHAPI Down gem download error: #{e.message}"
      raise # Re-raise the error to be caught by the caller
    rescue StandardError => e
      Rails.logger.error "WHAPI Generic download error: #{e.message}"
      raise # Re-raise
    end
    
    def extract_media_url(media_data)
      # Logic to get URL from different media types
      # Whapi seems to use 'link' for images, but maybe different for others?
      # Also handle the case where we need to construct it using media_id
      return media_data[:link] if media_data&.key?(:link)

      # If no link, try constructing from ID (this failed before for stickers)
      media_id = media_data[:id]
      if media_id.present?
          url = get_media_url_from_id(media_id)
          Rails.logger.info "WHAPI Constructed media URL from ID #{media_id}: #{url}" if url
          return url
      end

      Rails.logger.warn "WHAPI Could not find or construct media URL from data: #{media_data.inspect}"
      nil
    end
    
    def get_media_url_from_id(media_id)
      # Construct the URL based on Whapi documentation (/media/{id})
      # Ensure base URL is correct (using WHAPI_BASE_URL or similar)
      base_url = inbox.channel.provider_config['widget_url'] || 'https://gate.whapi.cloud' # Use configured or default
      # Ensure no double slashes
      "#{base_url.chomp('/')}/media/#{media_id}"
    end
    
    def download_attachment_with_retry(url, headers, max_retries = 3)
        attempts = 0
        begin
          attempts += 1
          # Using Down gem for robust downloading
          tempfile = Down.download(
            url,
            max_size: 100 * 1024 * 1024, # 100 MB limit
            headers: headers
            # timeout options can be added here if needed
            # open_timeout: 10,
            # read_timeout: 30
          )
          Rails.logger.info "WHAPI Download successful (attempt #{attempts}), tempfile size: #{tempfile.size}"
          return tempfile
        rescue Down::Error => e # Catch specific Down errors
          Rails.logger.error "WHAPI Down gem download error (attempt #{attempts}/#{max_retries}) for #{url}: #{e.message}"
          if attempts < max_retries && e.is_a?(Down::TimeoutError) # Only retry on timeout? Or other specific errors?
            sleep(attempts) # Basic exponential backoff
            retry
          else
            raise # Re-raise if max retries reached or non-retryable error
          end
        rescue StandardError => e
          Rails.logger.error "WHAPI Generic download error (attempt #{attempts}) for #{url}: #{e.message}"
          raise # Re-raise unexpected errors immediately
        end
    end
    
    def determine_mime_type(media_data, file = nil)
      # First try to get mime type from the payload
      mime_type = media_data[:mime_type]
      return mime_type if mime_type.present?

      # If not in payload, try inferring from the downloaded file using Marcel
      if file.present?
        begin
          # Rewind file if needed before analysis
          file.rewind
          inferred_mime = Marcel::MimeType.for(file)
          file.rewind # Rewind again after reading
          if inferred_mime.present?
              Rails.logger.info "WHAPI Inferred mime type using Marcel: #{inferred_mime}"
              return inferred_mime
          end
        rescue StandardError => e
          Rails.logger.error "WHAPI Error inferring mime type with Marcel: #{e.message}"
          # Fallback below
        end
      end

      # Fallback based on filename extension if available
      filename = media_data[:filename] || media_data[:caption]
      if filename.present? && filename.include?('.')
          extension = filename.split('.').last.downcase
          fallback_mime = Mime::Type.lookup_by_extension(extension)
          if fallback_mime
              Rails.logger.info "WHAPI Determined mime type by extension '.#{extension}': #{fallback_mime}"
              return fallback_mime.to_s
          end
      end


      Rails.logger.warn "WHAPI Could not determine mime type for media: #{media_data.inspect}. Defaulting to application/octet-stream."
      'application/octet-stream' # Default fallback
    end
    
    def contact_name(phone_number = nil)
      # Try payload first (Whapi sometimes includes contact profile in webhook)
      name = params[:contacts]&.first&.dig(:profile, :name)
      return name if name.present?

      # If not in payload, try fetching from Whapi API (if phone_number provided)
      if phone_number.present?
        begin
          # Assumes provider_service has a method to fetch contact info
          provider_service = inbox.channel.provider_service
          if provider_service.respond_to?(:fetch_contact_info)
            contact_info = provider_service.fetch_contact_info(phone_number) # Pass the number to fetch
            name = contact_info[:name] || contact_info[:pushname] # Use name or pushname
            Rails.logger.info "WHAPI Fetched contact name from API: #{name}" if name.present?
            return name if name.present?
          else
            Rails.logger.warn "WHAPI: provider_service does not support fetch_contact_info"
          end
        rescue StandardError => e
          # Log error but don't fail the whole process
          Rails.logger.error "WHAPI Error fetching contact info for #{phone_number}: #{e.message}"
        end
      end

      # Fallback
      Rails.logger.info "WHAPI Could not determine contact name, falling back."
      nil
    end
    
    def update_contact_with_whatsapp_profile(contact)
      return unless contact # Safety check

      phone_number = contact.phone_number
      return if phone_number.blank? # Need phone number to fetch profile

      # --- Optimization Check --- 
      last_checked_at_str = contact.additional_attributes['profile_updated_at']
      last_checked_at = last_checked_at_str ? Time.iso8601(last_checked_at_str) : nil
      profile_complete = contact.name.present? && !contact.name.starts_with?('+') && contact.avatar.attached?
      
      # Skip fetch if profile is complete and checked recently
      if profile_complete && last_checked_at.present? && last_checked_at > PROFILE_REFETCH_THRESHOLD.ago
        Rails.logger.info("WHAPI Skipping profile update check for contact #{contact.id}; checked recently at #{last_checked_at}")
        return
      elsif profile_complete
        Rails.logger.info("WHAPI Profile for contact #{contact.id} is complete, but last check was at #{last_checked_at || 'never'}. Re-checking.")
      else
        Rails.logger.info("WHAPI Profile for contact #{contact.id} is incomplete (Name: #{contact.name.present?}, Avatar: #{contact.avatar.attached?}). Fetching profile info.")
      end
      # --- End Optimization Check ---

      Rails.logger.info("WHAPI Attempting to update contact profile for #{contact.id} (#{phone_number})")

      begin
        provider_service = inbox.channel.provider_service
        contact_info = nil
        avatar_url = nil
        should_fetch_image = true # Default to true unless info endpoint provides URL

        # Fetch contact info using the provider service (returns a standardized hash)
        if provider_service.respond_to?(:fetch_contact_info)
           contact_info = provider_service.fetch_contact_info(phone_number)
           Rails.logger.info "WHAPI Fetched contact info via API: #{contact_info.inspect}" if contact_info
           # Check if info endpoint provided a URL
           if contact_info&.[](:avatar_url).present?
             avatar_url = contact_info[:avatar_url]
             should_fetch_image = false # Don't need dedicated image fetch if URL provided here
             Rails.logger.info("WHAPI Using avatar URL from /info or /chats endpoint: #{avatar_url}")
           end
        else
           Rails.logger.warn "WHAPI: provider_service does not support fetch_contact_info for profile update"
           contact_info = {} # Initialize to empty hash
        end

        # --- Fetch Avatar URL via /profile if needed ---
        if should_fetch_image && provider_service.respond_to?(:fetch_profile_image)
          Rails.logger.info("WHAPI No avatar URL from info endpoints, attempting to fetch via /profile endpoint.")
          begin
            fetched_url = provider_service.fetch_profile_image(phone_number) # Returns URL string or nil
            if fetched_url.present?
              avatar_url = fetched_url # Update avatar_url if found
              Rails.logger.info("WHAPI Successfully fetched avatar URL via /profile endpoint: #{avatar_url}")
            else
              Rails.logger.info("WHAPI /profile endpoint did not return an avatar URL.")
            end
          rescue StandardError => e
            Rails.logger.error("WHAPI Error calling fetch_profile_image: #{e.message}")
            # avatar_url remains nil or the value from contact_info
          end
        end

        # --- Prepare Updates ---
        updates = {}
        # Use the name directly from the fetched contact_info hash
        new_name = contact_info&.[](:name)

        # Update name only if it's different and not blank
        if new_name.present? && contact.name != new_name && !new_name.start_with?('+') # Avoid setting name back to phone number
          updates[:name] = new_name
          Rails.logger.info("WHAPI Updating contact name to: #{new_name}")
        end

        # --- Download and Attach Avatar if URL exists and is new ---
        current_avatar_url = contact.additional_attributes['avatar_url']
        new_avatar_downloaded = false # Flag to track if we actually downloaded
        
        if avatar_url.present? && avatar_url != current_avatar_url
          Rails.logger.info("WHAPI New avatar URL found, attempting download: #{avatar_url}")
          avatar_file = nil
          begin
            # Use download_attachment_with_retry to download the image from the URL
            auth_header = { 'Authorization' => "Bearer #{provider_service.api_key}" } 
            avatar_file = download_attachment_with_retry(avatar_url, auth_header) 

            if avatar_file
              filename = "#{contact.id}_avatar.jpg" 
              content_type = Marcel::MimeType.for(avatar_file) || 'image/jpeg'
              extension = content_type.split('/').last if content_type.include?('/')
              filename = "#{contact.id}_avatar.#{extension || 'jpg'}" if extension

              Rails.logger.info("WHAPI Attaching downloaded avatar with filename: #{filename}, content_type: #{content_type}")
              # Use a block to ensure attachment happens before attribute update
              contact.avatar.attach(io: avatar_file, filename: filename, content_type: content_type)
              new_avatar_downloaded = true # Set flag after successful attachment
              
              # Store the URL we successfully downloaded from
              current_attrs = updates[:additional_attributes] || contact.additional_attributes || {}
              updates[:additional_attributes] = current_attrs.merge('avatar_url' => avatar_url)
               
              Rails.logger.info("WHAPI Successfully attached new avatar for contact #{contact.id}")
            else
              Rails.logger.warn("WHAPI Download failed for avatar URL: #{avatar_url}")
            end

          rescue Down::Error => e
            Rails.logger.error("WHAPI Download failed for avatar from URL #{avatar_url}: #{e.message}")
          rescue StandardError => e
            Rails.logger.error("WHAPI Failed to process or attach downloaded avatar from #{avatar_url}: #{e.message}")
            Rails.logger.error(e.backtrace.join("\n"))
          ensure
            avatar_file&.close # Safely close tempfile if it exists
          end
        elsif avatar_url.present? # URL is same as current
          Rails.logger.info("WHAPI Avatar URL matches stored URL, skipping download and attachment.")
        else # No avatar URL found from any source
          Rails.logger.info("WHAPI No avatar URL available to download.")
        end

        # --- Apply Updates --- 
        # Always update the timestamp if we attempted a fetch (even if nothing changed)
        current_attrs = updates[:additional_attributes] || contact.additional_attributes || {}
        updates[:additional_attributes] = current_attrs.merge('profile_updated_at' => Time.current.utc.iso8601)

        # Only save if there are actual changes to name or avatar attributes
        if updates.key?(:name) || updates.dig(:additional_attributes, 'avatar_url') != current_avatar_url
          # Ensure additional_attributes are merged correctly if only avatar URL changed
          if updates.key?(:additional_attributes) && !updates.key?(:name) && new_avatar_downloaded
             # We only update additional_attributes if the avatar was actually downloaded and attached
             contact.update!(additional_attributes: updates[:additional_attributes])
             Rails.logger.info("WHAPI Contact profile updated successfully for #{contact.id}. Changes: additional_attributes (avatar_url)")
          elsif updates.key?(:name) # If name changed (and maybe avatar too)
             contact.update!(updates)
             Rails.logger.info("WHAPI Contact profile updated successfully for #{contact.id}. Changes: #{updates.keys.join(', ')}")
          else
            # Only timestamp changed, update separately if needed, or skip DB write if only timestamp updated.
            # Let's update only the timestamp if no other attributes changed during this fetch cycle.
            if !new_avatar_downloaded && !updates.key?(:name)
               contact.update_column(:additional_attributes, updates[:additional_attributes]) # Use update_column to skip callbacks if only timestamp changes
               Rails.logger.info("WHAPI Updated profile_updated_at timestamp for contact #{contact.id}")
            end
          end
        else
          Rails.logger.info("WHAPI No profile changes detected during fetch for contact #{contact.id}, updating timestamp only.")
          # Update timestamp even if no other data changed
          contact.update_column(:additional_attributes, updates[:additional_attributes]) # Use update_column to skip callbacks
        end

      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("WHAPI Failed to update contact profile (Validation Error): #{e.message} - #{e.record.errors.full_messages.join(', ')}")
      rescue StandardError => e
        Rails.logger.error("WHAPI Error during contact profile update for #{phone_number}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
    end
    
    def extract_quoted_message_details(context)
      return {} if context.blank? || context[:quoted_id].blank?

      quoted_message_id = context[:quoted_id]
      quoted_message_sender = context[:quoted_participant] # The sender of the original message
      quoted_message_content = context[:quoted_message] # May contain text/media info

      # Try to find the original message in Chatwoot by its source ID
      original_message = conversation.messages.find_by(source_id: quoted_message_id)

      details = {
        quoted_message_source_id: quoted_message_id,
        quoted_message_sender_source_id: quoted_message_sender
        # Add more details from quoted_message_content if needed
      }
      details[:quoted_message_id] = original_message.id if original_message # Link to Chatwoot message ID if found

      Rails.logger.info "WHAPI Extracted quoted message details: #{details}"
      details
    end
    
    def outgoing_message?(message_data)
      # Whapi uses 'from_me' to indicate messages sent by the connected number
      return true if message_data[:from_me] == true

      # Additionally, check if 'to' field is present (usually indicates outgoing)
      # and 'from' field matches the inbox identifier (sender is our number)
      # This helps catch outgoing messages if 'from_me' is missing/false unexpectedly
      if message_data[:to].present? && message_data[:from].present?
          # Normalize inbox identifier and message 'from' field for comparison
          inbox_identifier = inbox.identifier&.gsub(/\D/, '') # Get digits from inbox phone
          message_from = message_data[:from].gsub(/\D/, '') # Get digits from message sender
          if inbox_identifier.present? && message_from == inbox_identifier
              Rails.logger.info "WHAPI Identified message as outgoing based on 'to' field and 'from' matching inbox identifier."
              return true
          end
      end


      false # Default to incoming if not explicitly outgoing
    end
    
    def find_message_by_source_id_or_content(source_id, message_data)
      # First try to find by source_id
      message = Message.find_by(source_id: source_id)
      return message if message

      # If not found by source_id (e.g., message sent via Chatwoot API before webhook confirmation),
      # try to find a recent outgoing message to the same recipient with matching content/type.
      # This is a fallback and might be less reliable.

      Rails.logger.info "WHAPI Message not found by source_id #{source_id}, attempting content match."

      recipient_phone_number = message_data[:to] || message_data[:chat_id]&.split('@')&.first
      return nil if recipient_phone_number.blank? # Need recipient to search

      # Find the contact inbox for the recipient
      provider_service = inbox.channel.provider_service
      formatted_phone = "+#{recipient_phone_number}" unless recipient_phone_number.start_with?('+')
      id_formats = provider_service.format_whatsapp_id(formatted_phone)
      contact_source_id = id_formats[:clean]

      contact_inbox = inbox.contact_inboxes.find_by(source_id: contact_source_id)
      return nil unless contact_inbox

      # Search recent outgoing messages in the conversation
      conversation = contact_inbox.conversations.first # Assuming one conversation per contact_inbox
      return nil unless conversation

      # Look for outgoing messages without a source_id yet, sent recently
      potential_matches = conversation.messages
                                       .where(sender_id: nil, message_type: :outgoing, source_id: nil)
                                       .where('created_at > ?', 5.minutes.ago) # Adjust time window as needed
                                       .order(created_at: :desc)

      return nil if potential_matches.empty?

      # Try to match based on type and content/caption
      message_type = message_data[:type]
      content_to_match = message_data.dig(:text, :body) || message_data[:caption]

      matched_message = potential_matches.find do |potential_match|
        match = false
        case message_type
        when 'text'
          match = potential_match.content.present? && potential_match.content == content_to_match
        when 'image', 'video', 'audio', 'document', 'voice', 'sticker'
          # For attachments, matching caption might be sufficient? Or check attachment type?
          # This is less reliable as multiple attachments might have same/no caption.
          match = potential_match.content == content_to_match # Match caption
          # Additionally check attachment type if possible?
          # match &&= potential_match.attachments.first&.file_type == type_mapping(message_type)
        # Add other types if needed
        end
        match
      end

      if matched_message
        Rails.logger.info "WHAPI Found potential match by content: Message ##{matched_message.id}"
      else
        Rails.logger.info "WHAPI No content match found for outgoing message."
      end

      matched_message # Return the matched message or nil
    end
    
    def extract_filename_from_url(url)
        return nil if url.blank?
        begin
          uri = URI.parse(url)
          filename = File.basename(uri.path)
          # Decode URL encoding if present
          return URI.decode_www_form_component(filename) if filename.present?
        rescue URI::InvalidURIError => e
          Rails.logger.error "WHAPI Invalid URL for filename extraction: #{url} - #{e.message}"
        end
        nil
    end
  end