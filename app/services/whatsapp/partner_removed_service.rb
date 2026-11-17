# Handles Meta's `account_update` PARTNER_REMOVED webhook: the customer unshared their Messaging account
# (WABA) from our partner business, so every embedded signup inbox on it has lost API access.
# Prompting reauthorization shows the reconnect banner and emails the account admins.
class Whatsapp::PartnerRemovedService
  # Meta's disconnection_info reasons, sent only for numbers also on the WhatsApp Business app.
  DISCONNECTION_REASONS = %w[
    ACCOUNT_DISCONNECTED BUSINESS_DOWNGRADE CHANGE_NUMBER COMPANION_INACTIVITY PRIMARY_INACTIVITY USER_RE_REGISTERED
  ].freeze

  def initialize(waba_id, reason: nil)
    @waba_id = waba_id
    @reason = reason if DISCONNECTION_REASONS.include?(reason)
  end

  def perform
    Channel::Whatsapp.embedded_signup_on_waba(@waba_id).find_each do |channel|
      # Meta retries webhooks, so skip channels already flagged to avoid repeat disconnect emails.
      next if channel.reauthorization_required?

      Rails.logger.info("[WHATSAPP] Partner removed for WABA #{@waba_id} (#{@reason || 'no reason'}), prompting reauth for channel #{channel.id}")
      record_disconnection_reason(channel) if @reason
      channel.prompt_reauthorization!
    end
  end

  private

  # Shown in the reconnect banner and email, and cleared by Whatsapp::ReauthorizationService.
  # Skips validation, which re-checks the token against Meta and would fail now that our access is gone.
  def record_disconnection_reason(channel)
    channel.provider_config = channel.provider_config.merge('disconnection_reason' => @reason)
    channel.save!(validate: false)
  end
end
