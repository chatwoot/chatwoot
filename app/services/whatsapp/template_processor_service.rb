class Whatsapp::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    if template_params.present?
      process_template_with_params
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
    channel.message_templates.find do |t|
      t['name'] == template_params['name'] && t['language'] == template_params['language'] && t['status']&.downcase == 'approved'
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

  def validated_body_object(template)
    # we don't care if its not approved template
    return if template['status'] != 'approved'

    # we only care about text body object in template. if not present we discard the template
    # we don't support other forms of templates
    template['components'].find { |obj| obj['type'] == 'BODY' && obj.key?('text') }
  end
end
