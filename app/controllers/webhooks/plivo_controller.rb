class Webhooks::PlivoController < ActionController::API
  def process_payload
    channel = find_channel
    return head :not_found if channel.blank?
    return head :unauthorized unless valid_signature?(channel)

    Webhooks::PlivoEventsJob.perform_later(request.request_parameters.merge('phone_number' => params[:phone_number]))
    head :ok
  end

  private

  def find_channel
    return if to_number.blank?

    Channel::Plivo.find_by(phone_number: to_number)
  end

  def to_number
    number = params[:To].presence || params[:phone_number]
    return if number.blank?

    number.start_with?('+') ? number : "+#{number}"
  end

  def valid_signature?(channel)
    Plivo::SignatureValidator.new(
      auth_token: channel.provider_config['auth_token'],
      url: request.original_url.split('?').first,
      params: request.request_parameters,
      nonce: request.headers['X-Plivo-Signature-V3-Nonce'],
      signature: request.headers['X-Plivo-Signature-Ma-V3'].presence || request.headers['X-Plivo-Signature-V3']
    ).valid?
  end
end
