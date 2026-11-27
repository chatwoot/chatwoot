module HmacConcern
  def hmac_verified?
    return false unless hmac_verification_params_valid?

    ContactIdentity::Verifier.new(channel: hmac_channel, identifier: @contact.identifier, params: params).perform.verified?
  end

  private

  def hmac_verification_params_valid?
    @contact&.identifier.present? &&
      params[:identifier].to_s == @contact.identifier &&
      hmac_channel.present?
  end

  def hmac_channel
    return if @inbox.blank?

    @hmac_channel ||= @inbox.channel if @inbox.channel.respond_to?(:hmac_token)
  end
end
