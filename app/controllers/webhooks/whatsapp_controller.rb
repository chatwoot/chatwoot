class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    Webhooks::WhatsappEventsJob.perform_later(deep_symbolize_keys(params.to_unsafe_hash))
    head :ok
  end

  private

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def deep_symbolize_keys(hash)
    case hash
    when Array
      hash.map { |v| deep_symbolize_keys(v) }
    when Hash
      hash.each_with_object({}) do |(k, v), acc|
        sym_key = k.is_a?(String) ? k.to_sym : k
        acc[sym_key] = deep_symbolize_keys(v)
      end
    else
      hash
    end
  end
end
