# services from Meta (Prev: Facebook) needs a token verification step for webhook subscriptions,
# This concern handles the token verification step.

module MetaTokenVerifyConcern
  def verify
    service = self.is_a?(Webhooks::WhatsappController) ? 'whatsapp' : 'instagram'

    if valid_token?(params['hub.verify_token'], service)
      Rails.logger.info("#{service.capitalize} webhook verified")
      render json: params['hub.challenge']
    else
      render json: { error: 'Error; wrong verify token', status: 403 }
    end
  end

  private

  def valid_token?(token, service)
    if service == 'whatsapp'
      token == GlobalConfigService.load('WHATSAPP_VERIFY_TOKEN', '')
    else
      token == GlobalConfigService.load('IG_VERIFY_TOKEN', '')
    end
  end
end
