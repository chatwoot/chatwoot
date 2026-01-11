class Whatsapp::MessageTemplateService
  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
    @client = Whatsapp::FacebookApiClient.new(api_key)
  end

  def list_templates
    @client.list_message_templates(business_account_id)
  rescue StandardError => e
    Rails.logger.error "Error listing templates: #{e.message}"
    []
  end

  def upload_template_media(file)
    file_bytes = file.tempfile.read
    file_type = file.content_type

    handle = @client.upload_template_media(file_bytes: file_bytes, file_type: file_type)
    { success: true, handle: handle }
  rescue StandardError => e
    Rails.logger.error "Error uploading template media: #{e.message}"
    { success: false, error: e.message }
  end

  def create_template(template_data)
    template_name = template_data[:name] || template_data['name']
    Rails.logger.debug "Creating WhatsApp template with payload: #{template_data.to_json}"
    result = @client.create_message_template(business_account_id, template_data)
    Rails.logger.debug "Meta API response: #{result}"
    { success: true, template: result }
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    # Meta API sometimes times out but still creates the template
    # Check if template was actually created
    Rails.logger.warn "Timeout creating template '#{template_name}', checking if it was created..."
    if template_created?(template_name)
      Rails.logger.info "Template '#{template_name}' was created despite timeout"
      { success: true, template: { name: template_name, status: 'PENDING' } }
    else
      Rails.logger.error "Template creation timed out and template was not created: #{e.message}"
      { success: false, error: 'Request timed out. Please try again.' }
    end
  rescue StandardError => e
    Rails.logger.error "Error creating template: #{e.message}"
    { success: false, error: e.message }
  end

  def delete_template(template_name)
    @client.delete_message_template(business_account_id, template_name)
    { success: true }
  rescue StandardError => e
    Rails.logger.error "Error deleting template: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def template_created?(template_name)
    return false if template_name.blank?

    templates = list_templates
    templates.any? { |t| t['name'] == template_name }
  rescue StandardError => e
    Rails.logger.error "Error checking if template exists: #{e.message}"
    false
  end

  def business_account_id
    @whatsapp_channel.provider_config['business_account_id']
  end

  def api_key
    @whatsapp_channel.provider_config['api_key']
  end
end
