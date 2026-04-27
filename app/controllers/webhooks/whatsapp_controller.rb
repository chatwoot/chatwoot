class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    return false if token.blank?

    if params[:phone_number].present?
      channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
      if channel.present?
        expected = channel.provider_config['webhook_verify_token']
        return false if expected.blank?

        return ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected.to_s)
      end
    else
      return Channel::Whatsapp.where(provider: 'whatsapp_cloud')
                              .exists?(["provider_config->>'webhook_verify_token' = ?", token])
    end
    false
  end

  def inactive_whatsapp_number?
    phone_number = params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end
end
