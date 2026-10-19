module Enterprise::Account::CloudTrial
  # no_card: trialing on the free default plan; card: trialing on a paid plan picked in the billing portal;
  # ended: the trial ran out without a paid plan, so the account is back on the free plan.
  def cloud_trial_state
    return if billing_provider != Account::DEFAULT_BILLING_PROVIDER || custom_attributes['trial_started_at'].blank?

    on_default_plan = custom_attributes['plan_name'] == Enterprise::Billing::PlanConfiguration.default_plan&.dig('name')
    return on_default_plan ? 'no_card' : 'card' if custom_attributes['subscription_status'] == 'trialing'

    'ended' if on_default_plan
  end

  # A trial without a card can move between USD and its locale's currency, since nothing has been billed yet.
  def trial_currency_options
    locale_currency = Enterprise::Billing::Currencies.for_locale(locale)
    return [] unless Enterprise::Billing::Currencies.enabled? && locale_currency != Enterprise::Billing::Currencies::DEFAULT
    return [] unless cloud_trial_state == 'no_card'

    [Enterprise::Billing::Currencies::DEFAULT, locale_currency]
  end
end
