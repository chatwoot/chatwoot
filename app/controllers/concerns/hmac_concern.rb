module HmacConcern
  def hmac_verified?
    return false unless hmac_verification_params_valid?

    expected_hash = OpenSSL::HMAC.hexdigest(
      'sha256',
      hmac_channel.hmac_token,
      @contact.identifier
    )
    identifier_hash = params[:identifier_hash].to_s
    return false unless identifier_hash.bytesize == expected_hash.bytesize

    ActiveSupport::SecurityUtils.secure_compare(identifier_hash, expected_hash)
  end

  private

  def hmac_verification_params_valid?
    params[:identifier_hash].present? &&
      @contact&.identifier.present? &&
      params[:identifier].to_s == @contact.identifier &&
      hmac_channel.present?
  end

  def hmac_channel
    return if @inbox.blank?

    @hmac_channel ||= @inbox.channel if @inbox.channel.respond_to?(:hmac_token)
  end
end
