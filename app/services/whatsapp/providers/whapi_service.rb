class Whatsapp::Providers::WhapiService < Whatsapp::Providers::BaseService
    def send_message(phone_number, message)
      @message = message
      
      # Handle different message types (text, attachments, etc.)
      result = nil
      
      if message.content.present? && message.attachments.blank?
        result = send_text_message(phone_number, message)
      elsif message.attachments.present?
        result = send_attachment(phone_number, message)
      elsif message.content_type == 'input_select'
        result = send_interactive_message(phone_number, message)
      end
      
      # If the message was sent successfully and we have a message ID
      # Store the ID in the message record for later reference
      if result.present?
        Rails.logger.info("WHAPI message sent successfully with ID: #{result}")
      else
        Rails.logger.error("WHAPI message sending failed: no result ID")
      end
      
      result
    end
    
    def send_template(phone_number, template_info)
      # Implement template sending logic using the Whapi API
      # This would translate Chatwoot template format to Whapi's format
      
      # Get standardized ID formats
      id_formats = format_whatsapp_id(phone_number)
      
      name = template_info[:name]
      parameters = template_info[:parameters]
      
      # Call Whapi API to send template
      response = HTTParty.post(
        "#{api_base_url}/messages/template",
        headers: api_headers,
        body: {
          receiver: id_formats[:whatsapp_id], # Use WhatsApp ID format for messaging
          template: name,
          params: format_template_params(parameters)
        }.to_json
      )
      
      process_response(response)
    end
    
    def sync_templates
      # Fetch templates from Whapi API and store them in channel.message_templates
      response = HTTParty.get(
        "#{api_base_url}/account/templates",
        headers: api_headers
      )
      
      if response.success?
        whatsapp_channel.message_templates = process_templates(response.parsed_response)
        whatsapp_channel.mark_message_templates_updated
      else
        Rails.logger.error "Error syncing Whapi templates: #{response.body}"
      end
    end
    
    def fetch_contact_info(phone_number)
      # Fetch contact information from Whapi API
      begin
        # Get standardized ID formats
        id_formats = format_whatsapp_id(phone_number)
        
        Rails.logger.info "WHAPI attempting to fetch contact info for #{id_formats[:original]}"
        Rails.logger.info "WHAPI trying formats: clean=#{id_formats[:clean]}, whatsapp_id=#{id_formats[:whatsapp_id]}"
        
        # Try first with WhatsApp ID format
        response = HTTParty.get(
          "#{api_base_url}/contacts/#{id_formats[:whatsapp_id]}/info",
          headers: api_headers,
          timeout: 5
        )
        
        # If first attempt fails, try with clean number format
        if !response.success?
          Rails.logger.info "WHAPI first attempt failed, trying clean number format"
          response = HTTParty.get(
            "#{api_base_url}/contacts/#{id_formats[:clean]}/info",
            headers: api_headers,
            timeout: 5
          )
        end
        
        if response.success?
          Rails.logger.info "Successfully fetched contact info for #{id_formats[:original]}"
          return response.parsed_response
        else
          Rails.logger.error "Error fetching contact info for #{id_formats[:original]}: #{response.code} - #{response.body}"
          
          # Alternative approach: try to fetch from chat info instead
          alt_response = HTTParty.get(
            "#{api_base_url}/chats/#{id_formats[:whatsapp_id]}",
            headers: api_headers,
            timeout: 5
          )
          
          if alt_response.success?
            Rails.logger.info "Successfully fetched contact info from chat endpoint for #{id_formats[:original]}"
            return alt_response.parsed_response
          end
          
          Rails.logger.error "All attempts to fetch contact info failed."
          return nil
        end
      rescue => e
        Rails.logger.error "Exception fetching contact info for #{phone_number}: #{e.message}"
        return nil
      end
    end
    
    def fetch_profile_image(phone_number)
      # Fetch profile image from Whapi API
      begin
        # Get standardized ID formats
        id_formats = format_whatsapp_id(phone_number)
        
        Rails.logger.info "WHAPI attempting to fetch profile image for #{id_formats[:original]}"
        Rails.logger.info "WHAPI trying formats: clean=#{id_formats[:clean]}, whatsapp_id=#{id_formats[:whatsapp_id]}"
        
        # Try first with WhatsApp ID format
        response = HTTParty.get(
          "#{api_base_url}/contacts/#{id_formats[:whatsapp_id]}/image",
          headers: api_headers,
          timeout: 5
        )
        
        # If first attempt fails, try with clean number format
        if !response.success?
          Rails.logger.info "WHAPI first attempt failed, trying clean number format"
          response = HTTParty.get(
            "#{api_base_url}/contacts/#{id_formats[:clean]}/image",
            headers: api_headers,
            timeout: 5
          )
        end
        
        if response.success?
          Rails.logger.info "Successfully fetched profile image for #{id_formats[:original]}"
          return response.parsed_response
        else
          Rails.logger.error "Error fetching profile image for #{id_formats[:original]}: #{response.code} - #{response.body}"
          
          # Check documentation for alternate endpoints
          alt_response = HTTParty.get(
            "#{api_base_url}/chats/#{id_formats[:whatsapp_id]}/image",
            headers: api_headers,
            timeout: 5
          )
          
          if alt_response.success?
            Rails.logger.info "Successfully fetched profile image from alternate endpoint for #{id_formats[:original]}"
            return alt_response.parsed_response
          end
          
          Rails.logger.error "All attempts to fetch profile image failed."
          return nil
        end
      rescue => e
        Rails.logger.error "Exception fetching profile image for #{phone_number}: #{e.message}"
        return nil
      end
    end
    
    def validate_provider_config?
      return false if whatsapp_channel.provider_config.blank?
      return false if api_key.blank?
      
      # Make a test API call to validate credentials
      response = check_health_and_wakeup
      response.success?
    end
    
    def media_url(media_id)
      # Retrieve media URL from Whapi if needed
      # First check if media_id is already a URL
      if media_id.to_s.start_with?('http://', 'https://')
        Rails.logger.info("WHAPI media_url: ID is already a URL: #{media_id}")
        return media_id
      end
      
      # If not a direct URL, construct the media URL
      url = "#{api_base_url}/media/#{media_id}"
      Rails.logger.info("WHAPI media_url: Constructed URL: #{url}")
      url
    end
    
    def error_message(response)
      return '' if response.success?
      
      parsed_response = response.parsed_response
      error_message = parsed_response['error'] || parsed_response['message'] || 'Unknown error'
      "Whapi Error: #{error_message}"
    end
    
    # Handle voice messages specifically
    def send_voice_message(whatsapp_id, url, filename = nil)
      Rails.logger.info("WHAPI sending voice message to #{whatsapp_id}, URL: #{url}")
      
      response = HTTParty.post(
        "#{api_base_url}/messages/audio",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          media: url,
          mime_type: 'audio/ogg; codecs=opus',
          is_voice: true, # Indicate this is a voice message, not just audio
          filename: filename || "voice_message_#{Time.now.to_i}.ogg"
        }.to_json
      )
      
      Rails.logger.info("WHAPI voice message response: #{response.body}")
      process_response(response)
    end
    
    def send_audio(whatsapp_id, url, filename = nil)
      # Determine if this should be sent as voice or regular audio
      # If filename contains 'voice' or we can determine it's a voice message, use voice-specific method
      if filename.to_s.downcase.include?('voice') || url.to_s.downcase.include?('voice')
        Rails.logger.info("WHAPI detected voice message, using voice-specific method")
        return send_voice_message(whatsapp_id, url, filename)
      end
      
      Rails.logger.info("WHAPI sending audio message to #{whatsapp_id}, URL: #{url}")
      response = HTTParty.post(
        "#{api_base_url}/messages/audio",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          media: url,
          mime_type: 'audio/mpeg',
          filename: filename || "audio_#{Time.now.to_i}.mp3"
        }.to_json
      )
      
      process_response(response)
    end
    
    def api_key
      whatsapp_channel.provider_config['api_key']
    end
    
    def webhook_secret
      whatsapp_channel.provider_config['webhook_secret']
    end
    
    def api_base_url
      'https://gate.whapi.cloud'
    end
    
    def api_headers
      {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      }
    end
    
    # Format a phone number into the proper WhatsApp ID format
    # Returns a hash with different formats that can be used in the API
    def format_whatsapp_id(phone_number)
      # Remove any non-numeric characters (including + sign)
      clean_number = phone_number.to_s.gsub(/[^0-9]/, '')
      
      # Standard WhatsApp ID format for individual contacts: number@s.whatsapp.net
      whatsapp_id = "#{clean_number}@s.whatsapp.net"
      
      {
        clean: clean_number,         # Just the number: 50683023625
        whatsapp_id: whatsapp_id,    # Standard WhatsApp ID: 50683023625@s.whatsapp.net
        original: phone_number       # Original format provided
      }
    end
    
    private
    
    def check_health_and_wakeup
      # Check health status and wake up the service if needed
      HTTParty.get(
        "#{api_base_url}/health",
        headers: api_headers,
        query: {
          wakeup: "true",
          platform: "Chrome,Whapi,1.6.0",
          channel_type: "web"
        }
      )
    end
    
    def send_text_message(phone_number, message)
      # Add retry logic with health check
      max_retry_attempts = 2
      retry_delay_seconds = 5
      
      # Get standardized ID formats
      id_formats = format_whatsapp_id(phone_number)
      
      for attempt in 0..max_retry_attempts
        response = HTTParty.post(
          "#{api_base_url}/messages/text",
          headers: api_headers,
          body: {
            to: id_formats[:whatsapp_id], # Use WhatsApp ID format for messaging
            body: message.content
          }.to_json
        )
        
        if response.success?
          return process_response(response)
        elsif attempt < max_retry_attempts
          # Log the error and try to wake up the service
          Rails.logger.warn "Whapi send_text_message attempt #{attempt + 1} failed, trying to wake up service"
          check_health_and_wakeup
          sleep(retry_delay_seconds)
        else
          Rails.logger.error "Whapi send_text_message failed after #{max_retry_attempts} attempts: #{response.body}"
          return process_response(response)
        end
      end
    end
    
    def send_attachment(phone_number, message)
      attachment = message.attachments.first
      attachment_url = attachment.download_url
      
      # Get standardized ID formats
      id_formats = format_whatsapp_id(phone_number)
      
      content_type = attachment.file_type
      filename = attachment.file.filename.to_s
      caption = message.content.presence || ''
      
      Rails.logger.info("WHAPI sending attachment with content_type: #{content_type}, filename: #{filename}")
      
      if content_type.include?('image')
        send_image(id_formats[:whatsapp_id], attachment_url, caption)
      elsif content_type.include?('video')
        send_video(id_formats[:whatsapp_id], attachment_url, caption, filename)
      elsif content_type.include?('audio')
        # Check if this is a voice message
        is_voice_message = filename.to_s.include?('voice') || 
                          content_type.include?('ogg') || 
                          caption.to_s.downcase.include?('voice')
                          
        if is_voice_message
          Rails.logger.info("WHAPI detected voice message, sending as voice")
          send_voice_message(id_formats[:whatsapp_id], attachment_url, filename)
        else
          Rails.logger.info("WHAPI sending as regular audio")
          send_audio(id_formats[:whatsapp_id], attachment_url, filename)
        end
      else
        send_document(id_formats[:whatsapp_id], attachment_url, caption, filename)
      end
    end
    
    def send_image(whatsapp_id, url, caption = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/image",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          media: url,
          caption: caption || '',
          mime_type: 'image/jpeg'
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_video(whatsapp_id, url, caption = nil, filename = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/video",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          media: url,
          caption: caption || '',
          mime_type: 'video/mp4',
          filename: filename
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_document(whatsapp_id, url, caption = nil, filename = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/document",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          media: url,
          caption: caption || '',
          mime_type: 'application/pdf',
          filename: filename || 'document.pdf'
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_interactive_message(phone_number, message)
      # Get standardized ID formats
      id_formats = format_whatsapp_id(phone_number)
      
      items = message.content_attributes[:items] || []
      
      if items.length <= 3
        send_button_message(id_formats[:whatsapp_id], message)
      else
        send_list_message(id_formats[:whatsapp_id], message)
      end
    end
    
    def send_button_message(whatsapp_id, message)
      buttons = create_buttons(message.content_attributes[:items])
      
      response = HTTParty.post(
        "#{api_base_url}/messages/interactive",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          type: 'button',
          body: {
            text: message.content
          },
          action: {
            buttons: buttons
          }
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_list_message(whatsapp_id, message)
      rows = create_rows(message.content_attributes[:items])
      
      response = HTTParty.post(
        "#{api_base_url}/messages/interactive",
        headers: api_headers,
        body: {
          to: whatsapp_id,
          type: 'list',
          body: {
            text: message.content
          },
          action: {
            button: 'Choose an option',
            sections: [
              {
                rows: rows
              }
            ]
          }
        }.to_json
      )
      
      process_response(response)
    end
    
    def format_template_params(parameters)
      # Convert Chatwoot's template parameters format to Whapi's format
      # This will depend on how both systems structure their template parameters
      parameters_hash = {}
      
      parameters&.each_with_index do |param, index|
        parameters_hash[index + 1] = param[:text]
      end
      
      parameters_hash
    end
    
    def process_templates(templates_data)
      # Transform Whapi template data to match Chatwoot's expected format
      templates_data.map do |template|
        {
          'name' => template['name'],
          'namespace' => template['namespace'] || '',
          'language' => template['language'] || 'en',
          'status' => template['status'] || 'approved',
          'components' => format_template_components(template),
          'category' => template['category'] || ''
        }
      end
    end
    
    def format_template_components(template)
      # Format template components to match Chatwoot's expected structure
      components = []
      
      if template['body_text'].present?
        components << {
          'type' => 'BODY',
          'text' => template['body_text'],
          'parameters' => template['parameters'] || []
        }
      end
      
      if template['header_text'].present?
        components << {
          'type' => 'HEADER',
          'text' => template['header_text'],
          'format' => 'TEXT',
          'parameters' => template['header_parameters'] || []
        }
      end
      
      if template['footer_text'].present?
        components << {
          'type' => 'FOOTER',
          'text' => template['footer_text']
        }
      end
      
      if template['buttons'].present?
        components << {
          'type' => 'BUTTONS',
          'buttons' => template['buttons'].map { |btn| { 'type' => btn['type'], 'text' => btn['text'] } }
        }
      end
      
      components
    end
    
    def process_response(response)
      parsed_response = response.parsed_response
      
      # Log detailed response for debugging
      Rails.logger.info("WHAPI API response: #{response.code} - #{parsed_response}")
      
      if response.success?
        # Different WhatsApp providers have different response formats
        # Extract the message ID from the response
        # Whapi response nests the ID under {"message": {"id": "..."}}
        if parsed_response.is_a?(Hash)
          message_id = parsed_response.dig('message', 'id') || # Check nested first
                      parsed_response['id'] || 
                      parsed_response['message_id'] || 
                      parsed_response['messageId'] || 
                      parsed_response.dig('messages', 0, 'id')
          
          if message_id.present?
            Rails.logger.info("WHAPI processed message ID from response: #{message_id}")
            return message_id
          else
            Rails.logger.warn("WHAPI could not extract message ID from response: #{parsed_response}")
            # Return a dummy value as a fallback to prevent nil source_id
            return "success_#{Time.now.to_i}"
          end
        else
          Rails.logger.warn("WHAPI unexpected response format: #{parsed_response.class}")
          return "success_#{Time.now.to_i}"
        end
      else
        Rails.logger.error("WHAPI API call failed: #{response.code} - #{parsed_response}")
        nil
      end
    end
  end