# frozen_string_literal: true

FactoryBot.define do
  factory :account_addon do
    association :account
    association :addon
    duration_type { 'custom' }
    duration_months { nil }

    # Default to a period safely inside the account's current package so the
    # within-package validation passes. Falls back to a generic window when the
    # account has no package (used by negative tests) or in base builds.
    starts_at do
      if account.respond_to?(:current_account_package) && account.current_account_package
        account.current_account_package.starts_at + 1.day
      else
        1.month.ago
      end
    end

    ends_at do
      if account.respond_to?(:current_account_package) && account.current_account_package
        account.current_account_package.ends_at - 1.day
      else
        1.month.from_now
      end
    end
  end
end
