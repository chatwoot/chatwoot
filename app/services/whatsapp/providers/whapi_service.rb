class Whatsapp::Providers::WhapiService < Whatsapp::Providers::BaseService
    def send_message(phone_number, message)
      @message = message
      
      # Handle different message types (text, attachments, etc.)
      return send_text_message(phone_number, message) if message.content.present? && message.attachments.blank?
      return send_attachment(phone_number, message) if message.attachments.present?
      return send_interactive_message(phone_number, message) if message.content_type == 'input_select'
      
      nil
    end
    
    def send_template(phone_number, template_info)
      # Implement template sending logic using the Whapi API
      # This would translate Chatwoot template format to Whapi's format
      
      name = template_info[:name]
      parameters = template_info[:parameters]
      
      # Call Whapi API to send template
      response = HTTParty.post(
        "#{api_base_url}/messages/template",
        headers: api_headers,
        body: {
          receiver: phone_number,
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
    
    def validate_provider_config?
      return false if whatsapp_channel.provider_config.blank?
      return false if api_key.blank?
      
      # Make a test API call to validate credentials
      response = check_health_and_wakeup
      response.success?
    end
    
    def media_url(media_id)
      # Retrieve media URL from Whapi if needed
      # This might work differently in Whapi compared to other providers
      "#{api_base_url}/media/#{media_id}"
    end
    
    def error_message(response)
      return '' if response.success?
      
      parsed_response = response.parsed_response
      error_message = parsed_response['error'] || parsed_response['message'] || 'Unknown error'
      "Whapi Error: #{error_message}"
    end
    
    private
    
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
      
      for attempt in 0..max_retry_attempts
        response = HTTParty.post(
          "#{api_base_url}/messages/text",
          headers: api_headers,
          body: {
            to: phone_number,
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
      
      content_type = attachment.file_type
      filename = attachment.file.filename.to_s
      caption = message.content.presence || ''
      
      if content_type.include?('image')
        send_image(phone_number, attachment_url, caption)
      elsif content_type.include?('video')
        send_video(phone_number, attachment_url, caption, filename)
      elsif content_type.include?('audio')
        send_audio(phone_number, attachment_url)
      else
        send_document(phone_number, attachment_url, caption, filename)
      end
    end
    
    def send_image(phone_number, url, caption = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/image",
        headers: api_headers,
        body: {
          to: phone_number,
          media: url,
          caption: caption || '',
          mime_type: 'image/jpeg'
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_video(phone_number, url, caption = nil, filename = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/video",
        headers: api_headers,
        body: {
          to: phone_number,
          media: url,
          caption: caption || '',
          mime_type: 'video/mp4',
          filename: filename
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_audio(phone_number, url, filename = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/audio",
        headers: api_headers,
        body: {
          to: phone_number,
          media: url,
          mime_type: 'audio/mpeg',
          filename: filename
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_document(phone_number, url, caption = nil, filename = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/document",
        headers: api_headers,
        body: {
          to: phone_number,
          media: url,
          caption: caption || '',
          mime_type: 'application/pdf',
          filename: filename || 'document.pdf'
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_interactive_message(phone_number, message)
      items = message.content_attributes[:items] || []
      
      if items.length <= 3
        send_button_message(phone_number, message)
      else
        send_list_message(phone_number, message)
      end
    end
    
    def send_button_message(phone_number, message)
      buttons = create_buttons(message.content_attributes[:items])
      
      response = HTTParty.post(
        "#{api_base_url}/messages/interactive",
        headers: api_headers,
        body: {
          to: phone_number,
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
    
    def send_list_message(phone_number, message)
      rows = create_rows(message.content_attributes[:items])
      
      response = HTTParty.post(
        "#{api_base_url}/messages/interactive",
        headers: api_headers,
        body: {
          to: phone_number,
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
      
      if response.success? && parsed_response['error'].blank?
        if parsed_response['messages'].present? && parsed_response['messages'].first.present?
          return parsed_response['messages'].first['id']
        end
        
        # For other successful responses that don't follow the exact format
        return parsed_response['id'] if parsed_response['id'].present?
        return 'success'
      else
        handle_error(response)
        nil
      end
    end
  end