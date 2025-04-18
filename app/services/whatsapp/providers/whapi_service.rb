class Whatsapp::Providers::WhapiService < Whatsapp::Providers::BaseService
    def send_message(phone_number, message)
      @message = message
      
      # Handle different message types (text, attachments, etc.)
      return send_text_message(phone_number, message) if message.content.present?
      return send_attachment(phone_number, message) if message.attachments.present?
      
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
      response = HTTParty.get(
        "#{api_base_url}/account/info",
        headers: api_headers
      )
      
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
    
    def api_base_url
      'https://gate.whapi.cloud'
    end
    
    def api_headers
      {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      }
    end
    
    def send_text_message(phone_number, message)
      response = HTTParty.post(
        "#{api_base_url}/messages/text",
        headers: api_headers,
        body: {
          receiver: phone_number,
          message: message.content
        }.to_json
      )
      
      process_response(response)
    end
    
    def send_attachment(phone_number, message)
      attachment = message.attachments.first
      attachment_url = attachment.download_url
      
      content_type = attachment.file_type
      filename = attachment.file.filename
      
      if content_type.include?('image')
        send_image(phone_number, attachment_url, filename)
      elsif content_type.include?('video')
        send_video(phone_number, attachment_url, filename)
      elsif content_type.include?('audio')
        send_audio(phone_number, attachment_url)
      else
        send_document(phone_number, attachment_url, filename)
      end
    end
    
    def send_image(phone_number, url, caption = nil)
      response = HTTParty.post(
        "#{api_base_url}/messages/image",
        headers: api_headers,
        body: {
          receiver: phone_number,
          image: url,
          caption: caption
        }.to_json
      )
      
      process_response(response)
    end
    
    # Similar methods for send_video, send_audio, send_document
    # Implement according to the Whapi API documentation
    
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
      # This is a simplified example, you'll need to adjust based on actual data structure
      [
        {
          'type' => 'BODY',
          'text' => template['body_text'],
          'parameters' => template['parameters'] || []
        }
      ]
    end
  end