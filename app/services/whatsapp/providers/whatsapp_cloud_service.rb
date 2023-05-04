class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  require 'json'

  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_text_message_interactive(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        template: template_body_parameters(template_info),
        type: 'template'
      }.to_json
    )

    process_response(response)
  end

  def sync_templates
    templates = fetch_whatsapp_templates("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")

    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url)
    return [] unless response.success?

    next_url = next_url(response)

    return response['data'] + fetch_whatsapp_templates(next_url) if next_url.present?

    response['data']
  end

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    response = HTTParty.get("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")
    response.success?
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def media_url(media_id)
    "#{api_base_path}/v13.0/#{media_id}"
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path
    "#{api_base_path}/v13.0/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def business_account_path
    "#{api_base_path}/v14.0/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        text: { body: message.content },
        type: 'text'
      }.to_json
    )

    process_response(response)
  end

  def send_text_message_interactive(phone_number, message)
    buttons = []
    rows = []
    package_send = {}
    sections = []

    if message.content_attributes['items'].length <= 3

      message.content_attributes['items'].each do |item|
        button = { :type => 'reply', 'reply' => { 'id' => item['value'], 'title' => item['title'] } }
        buttons << button
      end

      hash_json = { 'buttons' => buttons }
      json_result = JSON.generate(hash_json)

      package_send = {
        'type': 'button',
        'body': {
          'text': message.content
        },
        'action': json_result
      }

    else
      message.content_attributes['items'].each do |item|
        row = { 'id' => item['value'], 'title' => item['title'] }
        rows << row
      end

      section1 = { 'rows' => rows }
      sections << section1
      hash_json = { :button => 'Escolha um item', 'sections' => sections }
      json_result = JSON.generate(hash_json)

      package_send = {
        'type': 'list',
        'body': {
          'text': message.content
        },
        'action': json_result
      }
    end

    buttons_itens = message.content_attributes[:items]
    buttons = buttons_itens.first
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: package_send,
        type: 'interactive'
      }.to_json
    )

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = message.content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        'to' => phone_number,
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response)
  end

  def process_response(response)
    if response.success?
      response['messages'].first['id']
    else
      Rails.logger.error response.body
      nil
    end
  end

  def template_body_parameters(template_info)
    {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      },
      components: [{
        type: 'body',
        parameters: template_info[:parameters]
      }]
    }
  end
end
