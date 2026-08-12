module Enterprise::Account::PackageLimits
  # Package limits override the enterprise plan limits (agents/inboxes) for the
  # keys a package defines; the remaining keys (captain) are carried through
  # untouched so the limits endpoint and captain services keep working.
  def usage_limits
    base = super
    assignment = current_account_package
    return base unless assignment

    package = assignment.package
    {
      agents: package.users_limit.presence || base[:agents],
      inboxes: package.channels_limit.presence || base[:inboxes],
      contacts: package.contacts_limit,
      conversations: package.conversations_limit,
      campaign_messages: package.campaign_messages_limit,
      captain: base[:captain]
    }
  end

  # An account without a valid, active package assignment is inactive, no
  # matter what the stored status enum says. This is the single runtime choke
  # point: every controller/webhook/job gate checks `account.active?`.
  def active?
    super && package_active?
  end

  def package_active?
    current_account_package.present?
  end

  def current_account_package
    account_packages
      .current
      .joins(:package)
      .where(packages: { status: Package.statuses[:active] })
      .order(:starts_at)
      .last
  end

  # The current month-bucket anchored at the assignment's start date (the first
  # day of the package is the first day from which the monthly count runs).
  # Returns [window_start, window_end) or nil when there is no active package.
  def package_usage_window
    assignment = current_account_package
    return unless assignment

    anchor = assignment.starts_at
    months = ((Time.current.year - anchor.year) * 12) + (Time.current.month - anchor.month)
    months -= 1 if Time.current.day < anchor.day
    window_start = anchor.advance(months: months)

    [window_start, window_start.advance(months: 1)]
  end
end
