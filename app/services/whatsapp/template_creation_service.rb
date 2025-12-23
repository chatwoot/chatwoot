class Whatsapp::TemplateCreationService
  pattr_initialize [:message_template!]

  def call
    return false unless valid_for_creation?
    return false unless validate_whatsapp_content

    process_media_uploads if media?
    create_template_on_whatsapp

    true
  rescue StandardError => e
    handle_creation_error(e)
    false
  end

  private

  def channel
    @channel ||= message_template.inbox.channel
  end

  def media?
    header_component && header_component['media'].present?
  end

  def header_component
    @header_component ||= message_template.content['components']&.find { |c| c['type'] == 'HEADER' }
  end

  def process_media_uploads
    blob_id = header_component['media']['blob_id']
    format = header_component['format']

    facebook_client = Whatsapp::FacebookApiClient.new
    response = facebook_client.upload_media_for_template(
      blob_id: blob_id,
      format: format
    )

    raise "Media upload failed: #{response[:error]}" unless response[:handle]

    update_component_with_handle(response[:handle])
  end

  def update_component_with_handle(handle)
    header_component['example'] ||= {}
    header_component['example']['header_handle'] = [handle]
    header_component.delete('media')
  end

  def create_template_on_whatsapp
    response = channel.provider_service.create_message_template(template_params)
    update_template_from_response(response)
  end

  def template_params
    {
      name: message_template.name,
      language: message_template.language,
      category: Whatsapp::TemplateFormatterService.format_category_for_meta(message_template.category),
      components: message_template.content['components'],
      parameter_format: Whatsapp::TemplateFormatterService.format_parameter_format_for_meta(
        message_template.parameter_format
      )
    }
  end

  def update_template_from_response(response)
    message_template.platform_template_id = response['id']
    message_template.status = Whatsapp::TemplateFormatterService.format_status_from_meta(
      response['status']
    ) || 'pending'
  end

  def handle_creation_error(error)
    Rails.logger.error "WhatsApp template creation failed: #{error.message}"
    message_template.errors.add(:base, "Failed to create template: #{error.message}")
  end

  def valid_for_creation?
    message_template.channel_type == 'Channel::Whatsapp' &&
      message_template.platform_template_id.blank?
  end

  def validate_whatsapp_content
    components = message_template.content['components']

    if components.blank?
      message_template.errors.add(:content, 'Components are required')
      return false
    end

    validate_whatsapp_components(components)
  end

  def validate_whatsapp_components(components)
    body_count = components.count { |c| c['type'] == 'BODY' }

    if body_count != 1
      message_template.errors.add(:content, 'Must have exactly one BODY component')
      return false
    end

    # NOTE: we can also add other components validation but meta will anyways do that so lets keep it simple
    true
  end
end
