class Internal::DeactivateExpiredPackagesJob < ApplicationJob
  queue_as :scheduled_jobs

  # Persists the derived inactive state: accounts whose stored status is
  # `active` but that no longer have a valid, active package assignment
  # (expired, removed, never assigned, or assigned to an inactive package) are
  # flipped to `suspended` so the Super Admin list and status scopes stay
  # accurate. Runtime gating is already handled immediately by Account#active?.
  def perform
    deactivate_expired_accounts
  end

  private

  def deactivate_expired_accounts
    accounts_without_active_package.each(&:suspended!)
  end

  def accounts_without_active_package
    Account.where(status: :active)
           .where.not(id: AccountPackage.current
                          .joins(:package)
                          .where(packages: { status: Package.statuses[:active] })
                          .select(:account_id))
  end
end
