class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  before_action :verify_meta_signature!, only: :process_payload
  before_action :verify_provider_token!, only: :process_payload

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    return head :ok if tracking_events_only?

    perform_whatsapp_events_job
  end

  private

  def perform_whatsapp_events_job
    perform_sync if params[:awaitResponse].present?
    return if performed?

    Webhooks::WhatsappEventsJob.perform_later(webhook_params)
    head :ok
  end

  def perform_sync
    Webhooks::WhatsappEventsJob.perform_now(webhook_params)
  rescue Whatsapp::IncomingMessageBaileysService::InvalidWebhookVerifyToken
    head :unauthorized
  rescue Whatsapp::IncomingMessageBaileysService::MessageNotFoundError
    head :not_found
  end

  # The 360dialog token travels in the query string and is only the door's key.
  def webhook_params
    params.to_unsafe_hash.except(:webhook_token)
  end

  # Providers Meta does not sign authenticate with a token of their own, and it has to be
  # checked here, before anything is queued: a check left to the job answers 200 to anyone
  # who guesses a number, which tells them the inbox exists and lets them fill the queue.
  # Baileys echoes the token in every body. Z-API cannot, so it posts to a URL that carries
  # the token (Webhooks::Whatsapp::ZapiController); this route only keeps taking an inbox
  # until that URL is confirmed, and refuses it from then on.
  # A session provider never posts here at all, and the job would read whatever came for
  # one of its numbers as a 360dialog message.
  def verify_provider_token!
    case whatsapp_channel&.provider
    when 'baileys'
      head :unauthorized unless matches_webhook_verify_token?(params[:webhookVerifyToken])
    when 'default'
      verify_360dialog_webhook_token!
    when 'zapi'
      refuse_confirmed_zapi_route!
    when *Whatsapp::Session::PROVIDERS
      head :unauthorized
    end
  end

  def refuse_confirmed_zapi_route!
    head :unauthorized if Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: whatsapp_channel).webhook_url_confirmed?
  end

  # 360dialog posts to the URL registered in `validate_provider_config?`, which carries the
  # channel's `webhook_token`. A channel saved before the token existed has none until its next
  # save, and is taken without one meanwhile.
  def verify_360dialog_webhook_token!
    expected_token = whatsapp_channel.provider_config['webhook_token']
    if expected_token.blank?
      Rails.logger.warn("[WHATSAPP] Accepted webhook without a webhook token for channel #{whatsapp_channel.id}")
      return
    end

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(params[:webhook_token].to_s, expected_token)
  end

  def matches_webhook_verify_token?(given)
    expected = whatsapp_channel.provider_config['webhook_verify_token']
    return false if given.blank? || expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(given.to_s, expected.to_s)
  end

  def tracking_events_only?
    return false unless params[:object] == 'whatsapp_business_account'

    changes = params.fetch(:entry, []).flat_map { |entry| entry.fetch(:changes, []) }
    changes.present? && changes.all? { |change| change[:field] == 'tracking_events' }
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

  # A Cloud or 360dialog inbox without a secret cannot have its webhooks verified, and is taken
  # unsigned only while WHATSAPP_ACCEPT_UNSIGNED_WEBHOOKS allows it: a grace period for the
  # inboxes set up before a secret was asked for, closed by setting it to false.
  def meta_signature_verification_required?
    return true if whatsapp_channel.blank?
    return false unless whatsapp_channel.provider.in?(%w[whatsapp_cloud default])
    return true if channel_meta_app_secrets(whatsapp_channel).present?
    return true if whatsapp_channel.provider_config['source'] == 'embedded_signup'

    !ActiveModel::Type::Boolean.new.cast(ENV.fetch('WHATSAPP_ACCEPT_UNSIGNED_WEBHOOKS', true))
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
