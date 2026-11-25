module Enterprise::Whatsapp::EmbeddedSignupEligibility
  TRIAL_DURATION = 15.days

  def enabled?
    super || (@account.created_at > TRIAL_DURATION.ago && @account.billing_provider == 'stripe' && ChatwootApp.chatwoot_cloud?)
  end
end
