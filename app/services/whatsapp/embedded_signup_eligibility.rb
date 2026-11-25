class Whatsapp::EmbeddedSignupEligibility
  FEATURE = 'whatsapp_embedded_signup_inbox_creation'.freeze

  def initialize(account)
    @account = account
  end

  def enabled?
    @account.feature_enabled?(FEATURE)
  end
end

Whatsapp::EmbeddedSignupEligibility.prepend_mod_with('Whatsapp::EmbeddedSignupEligibility')
