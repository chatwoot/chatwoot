# Handles Meta's `account_update` PARTNER_REMOVED webhook: the customer unshared their Messaging account
# (WABA) from our partner business, so every embedded signup inbox on it has lost API access.
# Prompting reauthorization shows the reconnect banner and emails the account admins.
class Whatsapp::PartnerRemovedService
  def initialize(waba_id)
    @waba_id = waba_id
  end

  def perform
    Channel::Whatsapp.embedded_signup_on_waba(@waba_id).find_each do |channel|
      # Meta retries webhooks, so skip channels already flagged to avoid repeat disconnect emails.
      next if channel.reauthorization_required?

      Rails.logger.info("[WHATSAPP] Partner removed for WABA #{@waba_id}, prompting reauthorization for channel #{channel.id}")
      channel.prompt_reauthorization!
    end
  end
end
