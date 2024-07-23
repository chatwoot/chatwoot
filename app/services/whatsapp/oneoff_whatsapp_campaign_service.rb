class Whatsapp::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]

  attr_accessor :processed_params

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      next if contact.phone_number.blank?

      template = fetch_template(campaign.whatsapp_template)
      template_params = template_params(template)
      send_template(to: contact.phone_number, template_info: template_params)
    end
  end

  def fetch_template(template_id)
    whatsapp_channel = find_channel_by_id(campaign.inbox.channel_id)
    return nil if whatsapp_channel.blank?

    whatsapp_channel.message_templates.find { |tmpl| tmpl['id'] == template_id }
  end

  def template_params(template)
    name = template['name']
    namespace = template['namespace']
    language = template['language']
    category = template['category']
    processed_params = campaign.template_variables

    [name, namespace, language, category, processed_params]
  end

  def template_string(template)
    body_component = template['components'].find { |component| component['type'] == 'BODY' }
    body_component ? body_component['text'] : nil
  end

  def process_variable(str)
    str.gsub(/{{|}}/, '')
  end

  def processed_string(template)
    template_str = template_string(template)

    return unless template_str

    template_str.gsub(/{{([^}]+)}}/) do |_match|
      variable = Regexp.last_match(1)
      variable_key = process_variable(variable)

      processed_params[variable_key] || "{{#{variable}}}"
    end
  end

  def processable_channel_message_template(template_params)
    if template_params.present?
      return [
        template_params[0],
        template_params[1],
        template_params[2],
        template_params[4]&.map { |_, value| { type: 'text', text: value } }
      ]
    end

    template = fetch_template(campaign.whatsapp_template)
    match_obj = template_match_object(template)

    processed_parameters = match_obj.captures.map { |x| { type: 'text', text: x } }

    [template['name'], template['namespace'], template['language'], processed_parameters]
  end

  def template_match_object(template)
    body_object = validated_body_object(template)
    return if body_object.blank?

    template_match_regex = build_template_match_regex(body_object['text'])

    message = processed_string(template)
    message.match(template_match_regex)
  end

  def build_template_match_regex(template_text)
    template_text = template_text.gsub(/{{\d}}/, '(.*)')
    template_text = Regexp.escape(template_text)
    template_text = template_text.gsub(Regexp.escape('(.*)'), '(.*)')
    template_match_string = "^#{template_text}$"

    Regexp.new template_match_string
  end

  def validated_body_object(template)
    return if template['status'] != 'approved'

    template['components'].find { |obj| obj['type'] == 'BODY' && obj.key?('text') }
  end

  def find_channel_by_id(channel_id)
    Channel::Whatsapp.find(channel_id)
  end

  def send_template(to:, template_info:)
    name, namespace, lang_code, processed_parameters = processable_channel_message_template(template_info)
    channel.send_template(to, {
                            name: name,
                            namespace: namespace,
                            lang_code: lang_code,
                            parameters: processed_parameters
                          })
  end
end
