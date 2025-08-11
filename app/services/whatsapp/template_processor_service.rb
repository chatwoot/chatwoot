class Whatsapp::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    if template_params.present?
      name, namespace, language, params = process_template_with_params
      components = build_components_from_params
      [name, namespace, language, params, components]
    else
      process_template_from_message
    end
  end

  private

  def process_template_with_params
    [
      template_params['name'],
      template_params['namespace'],
      template_params['language'],
      processed_templates_params
    ]
  end

  def process_template_from_message
    return [nil, nil, nil, nil] if message.blank?

    # Delete the following logic once the update for template_params is stable
    # see if we can match the message content to a template
    # An example template may look like "Your package has been shipped. It will be delivered in {{1}} business days.
    # We want to iterate over these templates with our message body and see if we can fit it to any of the templates
    # Then we use regex to parse the template varibles and convert them into the proper payload
    channel.message_templates&.each do |template|
      match_obj = template_match_object(template)
      next if match_obj.blank?

      # we have a match, now we need to parse the template variables and convert them into the wa recommended format
      processed_parameters = match_obj.captures.map { |x| { type: 'text', text: x } }

      # no need to look up further end the search
      return [template['name'], template['namespace'], template['language'], processed_parameters]
    end
    [nil, nil, nil, nil]
  end

  def template_match_object(template)
    body_object = validated_body_object(template)
    return if body_object.blank?
    return if body_object['text'].blank?

    template_match_regex = build_template_match_regex(body_object['text'])
    message.outgoing_content.match(template_match_regex)
  end

  def build_template_match_regex(template_text)
    # Converts the whatsapp template to a comparable regex string to check against the message content
    # the variables are of the format {{num}} ex:{{1}}

    # transform the template text into a regex string
    # we need to replace the {{num}} with matchers that can be used to capture the variables
    template_text = template_text.gsub(/{{\d}}/, '(.*)')
    # escape if there are regex characters in the template text
    template_text = Regexp.escape(template_text)
    # ensuring only the variables remain as capture groups
    template_text = template_text.gsub(Regexp.escape('(.*)'), '(.*)')

    template_match_string = "^#{template_text}$"
    Regexp.new template_match_string
  end

  def find_template
    channel.message_templates&.find do |t|
      t['name'] == template_params['name'] &&
        t['language'] == template_params['language'] &&
        t['status']&.downcase == 'approved'
    end
  end

  def processed_templates_params
    template = find_template
    return if template.blank?

    parameter_format = template['parameter_format']

    if parameter_format == 'NAMED'
      template_params['processed_params']&.map { |key, value| { type: 'text', parameter_name: key, text: value } }
    else
      template_params['processed_params']&.map { |_, value| { type: 'text', text: value } }
    end
  end

  # Build rich components array for WhatsApp Cloud/360dialog from provided params
  # Supports:
  # - Header media: { header: { type: 'image'|'video'|'document'|'text', url?, filename?, text? } }
  # - Footer text: { footer: { text: '...' } } (no parameters needed; ignored by API if defined in template)
  # - Buttons: { buttons: [ { type: 'URL'|'PHONE_NUMBER'|'QUICK_REPLY', text?, url_suffix?, phone_number? } ] }
  def build_components_from_params
    return unless template_params.is_a?(Hash)

    template = find_template
    return if template.blank?

    result_components = []

    header_def = template['components']&.find { |c| c['type'] == 'HEADER' }
    footer_def = template['components']&.find { |c| c['type'] == 'FOOTER' }
    buttons_def = template['components']&.find { |c| c['type'] == 'BUTTONS' }

    # Header
    if header_def.present? && template_params['header'].present?
      header_params = template_params['header'] || {}
      case header_params['type']&.to_s&.downcase
      when 'image', 'video'
        media_type = header_params['type']&.to_s&.downcase
        media_link = header_params['url']
        if media_link.present?
          result_components << {
            type: 'header',
            parameters: [
              { :type => media_type, media_type.to_sym => { link: media_link } }
            ]
          }
        end
      when 'document'
        media_link = header_params['url']
        filename = header_params['filename']
        if media_link.present?
          doc = { link: media_link }
          doc[:filename] = filename if filename.present?
          result_components << {
            type: 'header',
            parameters: [
              { type: 'document', document: doc }
            ]
          }
        end
      when 'text'
        if header_params['text'].present?
          result_components << {
            type: 'header',
            parameters: [{ type: 'text', text: header_params['text'] }]
          }
        end
      end
    end

    # Buttons (URL, QUICK_REPLY, PHONE_NUMBER, FLOW)
    if buttons_def.present? && template_params['buttons'].is_a?(Array)
      buttons_params = template_params['buttons'] || []
      # WhatsApp expects parameters per button only when dynamic
      buttons_params.each_with_index do |btn, idx|
        button_type = btn['type']&.to_s&.upcase
        case button_type
        when 'URL'
          suffix = btn['url_suffix'] || btn['text']
          next if suffix.blank?

          result_components << {
            type: 'button',
            sub_type: 'url',
            index: idx.to_s,
            parameters: [{ type: 'text', text: suffix }]
          }
        when 'FLOW'
          payload = btn['payload'] || {}
          # Accept convenience keys
          payload = { flow_id: btn['flow_id'], data: btn['params'] }.compact if payload.blank? && (btn['flow_id'].present? || btn['params'].present?)
          next if payload.blank?

          result_components << {
            type: 'button',
            sub_type: 'flow',
            index: idx.to_s,
            parameters: [{ type: 'payload', payload: payload }]
          }
        when 'PHONE_NUMBER'
          # No parameters required for static phone buttons
          next
        when 'QUICK_REPLY'
          # No parameters required for quick reply buttons
          next
        end
      end
    end

    # Footer
    if footer_def.present? && template_params['footer'].is_a?(Hash)
      footer_params = template_params['footer'] || {}
      footer_text = footer_params['text']
      if footer_text.present?
        result_components << {
          type: 'footer',
          parameters: [{ type: 'text', text: footer_text }]
        }
      end
    end

    result_components.presence
  end

  def validated_body_object(template)
    # Only use approved templates
    return if template['status'] != 'approved'

    # Return the BODY component even if it has no text; rich templates may rely on media or buttons
    template['components'].find { |obj| obj['type'] == 'BODY' }
  end
end
