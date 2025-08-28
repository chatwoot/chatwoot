# Configuration for inactive account purge feature
module InactiveAccountPurge
  # Number of days of inactivity before an account is considered for deletion
  # Can be overridden via environment variable
  INACTIVITY_THRESHOLD_DAYS = ENV.fetch('INACTIVE_ACCOUNT_THRESHOLD_DAYS', 30).to_i.days

  # Email domain for support contact
  SUPPORT_EMAIL = ENV.fetch('CHATWOOT_SUPPORT_EMAIL', 'hello@chatwoot.com')
end