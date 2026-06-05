# services from Meta (Prev: Facebook) needs a token verification step for webhook subscriptions,
# This concern handles the token verification step.

module MetaTokenVerifyConcern
  CHANNEL_APP_SECRET_KEYS = %w[app_secret app_secret_key client_secret api_secret].freeze
  META_SIGNATURE_HEADER = 'X-Hub-Signature-256'.freeze
  META_SIGNATURE_PREFIX = 'sha256='.freeze

  def verify
    service = is_a?(Webhooks::WhatsappController) ? 'whatsapp' : 'instagram'
    if valid_token?(params['hub.verify_token'])
      Rails.logger.info("#{service.capitalize} webhook verified")
      render json: params['hub.challenge']
    else
      render status: :unauthorized, json: { error: 'Error; wrong verify token' }
    end
  end

  private

  def verify_meta_signature!
    return unless meta_signature_verification_required?
    return if valid_meta_signature?

    head :unauthorized
  end

  def valid_meta_signature?
    signature = request.headers[META_SIGNATURE_HEADER]
    return false unless signature&.start_with?(META_SIGNATURE_PREFIX)

    meta_app_secrets.any? do |secret|
      next false if secret.blank?

      expected_signature = "#{META_SIGNATURE_PREFIX}#{OpenSSL::HMAC.hexdigest('SHA256', secret, meta_request_body)}"
      ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
    end
  end

  def meta_request_body
    @meta_request_body ||= request.raw_post
  end

  def meta_app_secrets
    raise 'Overwrite this method in your controller'
  end

  def meta_signature_verification_required?
    true
  end

  def channel_meta_app_secrets(channel)
    return [] if channel.blank?

    secrets = []
    secrets << channel.app_secret if channel.respond_to?(:app_secret)
    secrets.concat(provider_config_meta_app_secrets(channel))
    secrets.compact_blank.uniq
  end

  def provider_config_meta_app_secrets(channel)
    return [] unless channel.respond_to?(:provider_config)

    provider_config = channel.provider_config.to_h.with_indifferent_access
    CHANNEL_APP_SECRET_KEYS.filter_map { |key| provider_config[key].presence }
  end

  def valid_token?(_token)
    raise 'Overwrite this method your controller'
  end
end
