class Twilio::TemplateSyncService
  pattr_initialize [:channel!]

  def call
    fetch_templates_from_twilio
    update_channel_templates
    mark_templates_updated
  rescue Twilio::REST::TwilioError => e
    Rails.logger.error("Twilio template sync failed: #{e.message}")
    false
  end

  private

  def fetch_templates_from_twilio
    @templates = client.content.v1.contents.list(limit: 1000)
  end

  def update_channel_templates
    formatted_templates = @templates.map { |template| format_template(template) }

    channel.update!(
      content_templates: { templates: formatted_templates },
      content_templates_last_updated: Time.current
    )
  end

  def format_template(template)
    {
      content_sid: template.sid,
      friendly_name: template.friendly_name,
      language: template.language,
      status: derive_status(template),
      template_type: derive_template_type(template),
      media_type: derive_media_type(template),
      variables: template.variables || {},
      category: derive_category(template),
      body: extract_body_content(template),
      types: template.types,
      created_at: template.date_created,
      updated_at: template.date_updated
    }
  end

  def mark_templates_updated
    channel.update!(content_templates_last_updated: Time.current)
  end

  def client
    @client ||= channel.send(:client)
  end

  def derive_status(_template)
    # For now, assume all fetched templates are approved
    # In the future, this could check approval status from Twilio
    'approved'
  end

  def derive_template_type(template)
    template_types = template.types.keys

    if template_types.include?('twilio/media')
      'media'
    elsif template_types.include?('twilio/quick-reply')
      'quick_reply'
    elsif template_types.include?('twilio/catalog')
      'catalog'
    else
      'text'
    end
  end

  def derive_media_type(template)
    return nil unless derive_template_type(template) == 'media'

    media_content = template.types['twilio/media']
    return nil unless media_content

    if media_content['image']
      'image'
    elsif media_content['video']
      'video'
    elsif media_content['document']
      'document'
    end
  end

  def derive_category(template)
    # Map template friendly names or other attributes to categories
    # For now, use utility as default
    case template.friendly_name
    when /marketing|promo|offer|sale/i
      'marketing'
    when /auth|otp|verify|code/i
      'authentication'
    else
      'utility'
    end
  end

  def extract_body_content(template)
    template_types = template.types

    if template_types['twilio/text']
      template_types['twilio/text']['body']
    elsif template_types['twilio/media']
      template_types['twilio/media']['body']
    elsif template_types['twilio/quick-reply']
      template_types['twilio/quick-reply']['body']
    elsif template_types['twilio/catalog']
      template_types['twilio/catalog']['body']
    else
      ''
    end
  end
end
