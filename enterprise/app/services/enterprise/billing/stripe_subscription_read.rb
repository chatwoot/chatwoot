# Reads a Stripe subscription as it is now and notes when the read started on the database clock, which every
# host shares, so concurrent deliveries handled on different hosts can tell whose read is newer.
class Enterprise::Billing::StripeSubscriptionRead
  APPLIED_READ_STARTED_AT = 'stripe_subscription_read_started_at'.freeze

  attr_reader :subscription

  def initialize(subscription_id:, stripe_version:)
    @started_at = database_time
    @subscription = Stripe::Subscription.retrieve(subscription_id, { stripe_version: stripe_version })
  end

  # A read that started later has already been applied, so it saw a subscription at least as new as this one.
  def overtaken_on?(account)
    applied_started_at = account.internal_attributes[APPLIED_READ_STARTED_AT]
    applied_started_at.present? && Time.zone.parse(applied_started_at) > @started_at
  end

  def mark_applied(internal_attributes)
    internal_attributes.merge(APPLIED_READ_STARTED_AT => @started_at.iso8601(6))
  end

  private

  # Uncached so a request that handles several events never reuses an earlier reading.
  def database_time
    clock_query = Arel::SelectManager.new.project(Arel::Nodes::NamedFunction.new('CLOCK_TIMESTAMP', []))
    Account.uncached { Account.connection.select_value(clock_query) }
  end
end
