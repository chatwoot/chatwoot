module Enterprise::Account::PackageLimits
  # Package limits override the enterprise plan limits (agents/inboxes) for the
  # keys a package defines; the remaining keys (captain) are carried through
  # untouched so the limits endpoint and captain services keep working.
  def usage_limits
    base = super
    assignment = current_account_package
    return base unless assignment

    package = assignment.package
    limits = {
      agents: package.users_limit.presence || base[:agents],
      inboxes: package.channels_limit.presence || base[:inboxes],
      contacts: package.contacts_limit,
      conversations: package.conversations_limit,
      campaign_messages: package.campaign_messages_limit,
      captain: base[:captain]
    }

    # Add-ons boost the base plan's limits additively. An add-on only counts when
    # it is active, its period is current, and it extends the account's current
    # base plan. A nil limit on either side means "unlimited", which stays unlimited.
    active_addons.each do |addon|
      limits[:agents] = add_limit(limits[:agents], addon.users_limit)
      limits[:inboxes] = add_limit(limits[:inboxes], addon.channels_limit)
      limits[:contacts] = add_limit(limits[:contacts], addon.contacts_limit)
      limits[:conversations] = add_limit(limits[:conversations], addon.conversations_limit)
      limits[:campaign_messages] = add_limit(limits[:campaign_messages], addon.campaign_messages_limit)
    end

    limits
  end

  # Add-ons that currently count towards the account's limits: active, within
  # their period, and tied to the account's current, active base plan.
  def active_addons
    addons.current.joins(:package).where(packages: { status: Package.statuses[:active] })
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

  private

  def add_limit(base_limit, boost)
    # A nil limit on either side means unlimited; an unlimited base cannot be
    # boosted and an empty boost leaves the base untouched.
    return base_limit if boost.blank? || base_limit.blank?

    base_limit + boost
  end
end
