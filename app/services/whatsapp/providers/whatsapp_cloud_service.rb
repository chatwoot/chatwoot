class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
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
        type: 'template',
        recepient_type: 'individual'
      }.to_json
    )
    process_response(response)
  end

  def template_body_parameters(template_info)
    parameters = []

    if template_info[:media].present?
      media_url = template_info[:media].first[:image][:link]
      media_id = upload_media_to_whatsapp(media_url)

      parameters << { type: 'image', image: { id: media_id } } if media_id
    end

    {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      },
      components: [
        {
          type: 'header',
          parameters: parameters
        },
        {
          type: 'body',
          parameters: template_info[:parameters] || []
        }
      ]
    }
  end

  def sync_templates
    # ensuring that channels with wrong provider config wouldn't keep trying to sync templates
    whatsapp_channel.mark_message_templates_updated
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

  def business_account_path
    "#{api_base_path}/v14.0/#{whatsapp_channel.provider_config['business_account_id']}"
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

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        to: phone_number,
        text: { body: message.content },
        type: 'text'
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
        :context => whatsapp_reply_context(message),
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

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response)
  end

  private

  def download_from_whatsapp(url)
    response = HTTParty.get(
      url,
      headers: { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}" },
      follow_redirects: true
    )

    return nil unless response.success?

    {
      content: response.body,
      content_type: response.headers['content-type']
    }
  end

  def upload_media_to_whatsapp(url)
    # Download the file using existing method
    media_data = download_from_whatsapp(url)
    return nil unless media_data

    # Create temporary file with proper extension
    temp_file = Tempfile.new(['whatsapp_media', mime_to_extension(media_data[:content_type])])
    temp_file.binmode
    temp_file.write(media_data[:content])
    temp_file.rewind

    # Upload to WhatsApp
    upload_response = HTTParty.post(
      "#{phone_id_path}/media",
      headers: { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}" },
      multipart: true,
      body: {
        messaging_product: 'whatsapp',
        file: File.new(temp_file.path),
        type: media_data[:content_type]
      }
    )

    upload_response['id'] if upload_response.success?
  rescue StandardError => e
    nil
  ensure
    temp_file&.close
    temp_file&.unlink
  end

  def mime_to_extension(content_type)
    {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/gif' => '.gif',
      'video/mp4' => '.mp4',
      'audio/mpeg' => '.mp3',
      'audio/ogg' => '.ogg',
      'application/pdf' => '.pdf'
    }[content_type&.downcase] || '.bin'
  end
end
