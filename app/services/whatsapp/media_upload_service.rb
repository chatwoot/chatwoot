class Whatsapp::MediaUploadService
  # Uploads media to WhatsApp's Media API and returns a media_id.
  # This is needed because template message media must be accessible
  # by Meta's servers. Local/ActiveStorage URLs won't work.
  #
  # Usage:
  #   service = Whatsapp::MediaUploadService.new(channel: channel)
  #   media_id = service.upload_from_url(url, content_type)
  #
  pattr_initialize [:channel!]

  def upload_from_url(url, content_type = nil)
    file_data, detected_type = download_file(url)
    return nil if file_data.blank?

    actual_type = content_type.presence || detected_type
    upload_to_whatsapp(file_data, actual_type)
  end

  private

  def download_file(url)
    response = HTTParty.get(url, follow_redirects: true, timeout: 30)
    return [nil, nil] unless response.success?

    content_type = response.headers['content-type']&.split(';')&.first
    [response.body, content_type]
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP] Failed to download media from #{url}: #{e.message}"
    [nil, nil]
  end

  def upload_to_whatsapp(file_data, content_type)
    phone_id = channel.provider_config['phone_number_id']
    token = channel.provider_config['api_key']
    url = URI("#{api_base}/v13.0/#{phone_id}/media")

    request = Net::HTTP::Post.new(url)
    request['Authorization'] = "Bearer #{token}"
    form_data = [
      %w[messaging_product whatsapp],
      ['type', content_type],
      ['file', file_data, { filename: filename_for(content_type), content_type: content_type }]
    ]
    request.set_form(form_data, 'multipart/form-data')

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 30
    response = http.request(request)

    handle_response(response)
  end

  def handle_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn "[WHATSAPP] Media upload failed: #{response.code} — #{response.body&.truncate(300)}"
      return nil
    end

    media_id = JSON.parse(response.body)['id']
    Rails.logger.info "[WHATSAPP] Media uploaded successfully: #{media_id}"
    media_id
  rescue JSON::ParserError => e
    Rails.logger.warn "[WHATSAPP] Failed to parse media upload response: #{e.message}"
    nil
  end

  def filename_for(content_type)
    extensions = {
      'image/jpeg' => 'image.jpg',
      'image/png' => 'image.png',
      'video/mp4' => 'video.mp4',
      'application/pdf' => 'document.pdf'
    }
    extensions[content_type] || 'file'
  end

  def api_base
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
