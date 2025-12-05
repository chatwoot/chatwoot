class Webhooks::WhatsappWebController < ActionController::API
  before_action :validate_hmac

  def process_payload
    raw = request.raw_post
    data = parse_payload(raw)

    Rails.logger.info "WhatsApp Web webhook received for #{params[:phone_number]}"

    Webhooks::WhatsappEventsJob.perform_later({
                                                'phone_number' => params[:phone_number],
                                                'payload' => data
                                              })

    head :ok
  rescue StandardError => e
    Rails.logger.error "Error processing WhatsApp Web webhook: #{e.message}"
    head :unprocessable_entity
  end

  private

  def validate_hmac
    return head :unauthorized unless valid_hmac?
  end

  def parse_payload(raw)
    JSON.parse(raw)
  rescue JSON::ParserError => e
    Rails.logger.warn "Invalid JSON in WhatsApp Web webhook: #{e.message}"
    # Return only safe parameters, avoiding to_unsafe_hash
    params.except(:controller, :action).permit!.to_h
  end

  def valid_hmac?
    signature = request.headers['X-Hub-Signature-256'].to_s
    return false if signature.blank?

    secret = ENV.fetch('WHATSAPP_WEBHOOK_SECRET', nil)
    if secret.blank?
      channel = find_whatsapp_channel
      return false if channel.blank?

      secret = channel.provider_config['webhook_secret']

      if secret.blank?
        Rails.logger.error "Webhook secret not configured for WhatsApp Web channel #{channel.id}"
        return false
      end
    end

    verify_signature(signature, secret)
  end

  def find_whatsapp_channel
    incoming = params[:phone_number].to_s
    return nil if incoming.blank?

    digits = incoming.gsub(/[^0-9]/, '')

    Channel::Whatsapp.where(provider: 'whatsapp_web').find_by(
      phone_number: [incoming, "+#{digits}", digits]
    )
  end

  def verify_signature(signature, secret)
    raw = request.raw_post
    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, raw)
    provided = signature.sub(/^sha256=/, '')

    # constant time comparison
    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end
end
