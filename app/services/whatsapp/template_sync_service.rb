class Whatsapp::TemplateSyncService
  pattr_initialize [:channel!, :templates!]

  def call
    sync_templates_to_database
    # TODO: if a template is deleted on meta then cleanup is required not sure if we should just delete them
    true
  rescue StandardError => e
    Rails.logger.error "WhatsApp template sync failed: #{e.message}"
    false
  end

  private

  def sync_templates_to_database
    templates.each do |template_data|
      sync_individual_template(template_data)
    end
  end

  def sync_individual_template(template_data)
    message_template = find_or_initialize_template(template_data)
    message_template.skip_provider_sync = true
    update_template_attributes(message_template, template_data)
    message_template.save!
  rescue StandardError => e
    Rails.logger.error "Failed to sync template #{template_data['id']}: #{e.message}"
  ensure
    message_template&.skip_provider_sync = false
  end

  def find_or_initialize_template(template_data)
    MessageTemplate.find_or_initialize_by(
      platform_template_id: template_data['id'],
      account: channel.account,
      inbox: channel.inbox
    )
  end

  def update_template_attributes(template, data)
    template.assign_attributes(
      name: data['name'],
      status: Whatsapp::TemplateFormatterService.format_status_from_meta(data['status']),
      category: Whatsapp::TemplateFormatterService.format_category_from_meta(data['category']),
      language: normalize_language_code(data['language']),
      channel_type: 'Channel::Whatsapp',
      parameter_format: Whatsapp::TemplateFormatterService.format_parameter_format_from_meta(data['parameter_format']),
      content: data.slice('components'),
      metadata: extract_metadata(data),
      last_synced_at: Time.current
    )
  end

  def normalize_language_code(language_code)
    # meta returns codes like en_US we store as en
    return language_code if language_code.length == 2

    # extract two letter language code en_US -> en
    language_code.split('_').first.downcase
  end

  def extract_metadata(data)
    {
      whatsapp_sub_category: data['sub_category']
    }.compact
  end
end
