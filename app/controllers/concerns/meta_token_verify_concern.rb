# services from Meta (Prev: Facebook) needs a token verification step for webhook subscriptions,
# This concern handles the token verification step.

module MetaTokenVerifyConcern
  def verify
    service =
      if is_a?(Webhooks::FacebookController)
        'facebook'
      elsif is_a?(Webhooks::WhatsappController)
        'whatsapp'
      elsif is_a?(Webhooks::InstagramController)
        'instagram'
      else
        'unknown'
      end

      if valid_token?(params['hub.verify_token'])
        Rails.logger.info("#{service.capitalize} webhook verified")
        render json: params['hub.challenge']
      end   
  end

  private

  def valid_token?(_token)
    raise 'Overwrite this method your controller'
  end
end
