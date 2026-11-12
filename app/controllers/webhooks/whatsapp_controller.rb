class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  before_action :verify_meta_signature!, only: :process_payload
  before_action :verify_webhook_token!, only: :process_payload

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    return head :ok if tracking_events_only?

    payload = trusted_payload
    Webhooks::WhatsappEventsJob.perform_later(payload) if payload.present?
    head :ok
  end

  private

  def tracking_events_only?
    return false unless params[:object] == 'whatsapp_business_account'

    changes = params.fetch(:entry, []).flat_map { |entry| entry.fetch(:changes, []) }
    changes.present? && changes.all? { |change| change[:field] == 'tracking_events' }
  end

  # account_update describes the sending app's own partner relationship. Customers' own Meta apps can point their
  # app-level webhook at an inbox URL, so drop those changes unless the request is signed with our app secret.
  def trusted_payload
    payload = params.to_unsafe_hash.except(:webhook_token)
    return payload if meta_signature_matches?(GlobalConfigService.load('WHATSAPP_APP_SECRET', nil))

    Whatsapp::AccountUpdates.without(payload)
  end

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def meta_app_secrets
    [
      *channel_meta_app_secrets(whatsapp_channel),
      GlobalConfigService.load('WHATSAPP_APP_SECRET', nil)
    ]
  end

  def whatsapp_channel
    @whatsapp_channel ||= whatsapp_business_payload_channel || Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end

  def meta_signature_verification_required?
    return true if whatsapp_channel.blank?

    whatsapp_channel.provider == 'whatsapp_cloud'
  end

  def verify_meta_signature!
    return super unless app_secret_pending?
    return if valid_meta_signature?

    Rails.logger.warn("[WHATSAPP_APP_SECRET_PENDING] unverified webhook accepted account_id=#{whatsapp_channel.account_id} " \
                      "channel_id=#{whatsapp_channel.id}")
  end

  def app_secret_pending?
    whatsapp_channel&.app_secret_pending? && channel_meta_app_secrets(whatsapp_channel).blank?
  end

  def verify_webhook_token!
    return unless whatsapp_channel&.provider == 'default'

    expected_token = whatsapp_channel.provider_config['webhook_token']
    if expected_token.blank?
      Rails.logger.warn("[WHATSAPP] Accepted webhook without a webhook token for channel #{whatsapp_channel.id}")
      return
    end

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(params[:webhook_token].to_s, expected_token)
  end

  def whatsapp_business_payload_channel
    return unless params[:object] == 'whatsapp_business_account'

    metadata = params.dig(:entry, 0, :changes, 0, :value, :metadata)
    return if metadata.blank?

    Whatsapp::WebhookChannelFinderService.new(
      display_phone_number: metadata[:display_phone_number],
      phone_number_id: metadata[:phone_number_id]
    ).perform
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
