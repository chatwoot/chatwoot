class Fonnte::FonnteService
  def send_message(to:, message:, token: nil, url: nil)
    payload = {
      target: to,
      message: message,
      typing: true
    }
    payload[:url] = url if url.present?

    response = HTTParty.post(
      'https://api.fonnte.com/send',
      headers: {
        'Authorization' => token,
        'Content-Type' => 'application/json'
      },
      body: payload.to_json
    )

    process_response(response)
  end

  def device_token(phone_number)
    response = HTTParty.post(
      'https://api.fonnte.com/get-devices',
      headers: {
        'Authorization' => ENV.fetch('FONNTE_ACCOUNT_TOKEN', nil)
      }
    )
    data = process_response(response)

    return unless data['status']

    device = data['data'].find { |d| d['device'] == phone_number }
    return device['token'] if device
  end

  private

  def process_response(response)
    raise StandardError, 'Failed to send message via Fonnte' unless response.success?

    Rails.logger.info "Fonnte send_message error: #{response.body}"

    response.parsed_response
  end
end
