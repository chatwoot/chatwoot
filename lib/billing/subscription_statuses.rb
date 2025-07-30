# frozen_string_literal: true

module Billing
  # Stripe subscription status constants
  # https://stripe.com/docs/api/subscriptions/object#subscription_object-status
  module SubscriptionStatuses
    # Stripe subscription statuses
    ACTIVE = 'active'           # Subscription is active and current
    CANCELED = 'canceled'       # Subscription has been canceled
    INCOMPLETE = 'incomplete'   # Initial payment not yet successful
    INCOMPLETE_EXPIRED = 'incomplete_expired' # Initial payment failed after retries
    PAST_DUE = 'past_due'      # Payment failed and subscription is past due
    TRIALING = 'trialing'      # Subscription is in trial period
    UNPAID = 'unpaid'          # Payment failed and subscription is unpaid
    PAUSED = 'paused'          # Subscription is paused

    # Application-specific statuses
    INACTIVE = 'inactive'       # Application status for ended subscriptions

    # Status groups for easier filtering
    PAID_STATUSES = [ACTIVE, TRIALING].freeze
    FAILED_PAYMENT_STATUSES = [PAST_DUE, CANCELED, UNPAID].freeze
    ALL_STRIPE_STATUSES = [
      ACTIVE, CANCELED, INCOMPLETE, INCOMPLETE_EXPIRED,
      PAST_DUE, TRIALING, UNPAID, PAUSED
    ].freeze

    # Check if status indicates subscription should have paid features
    def self.paid_status?(status)
      PAID_STATUSES.include?(status)
    end

    # Check if status indicates payment failure requiring community plan transition
    def self.failed_payment_status?(status)
      FAILED_PAYMENT_STATUSES.include?(status)
    end

    # Check if status is a valid Stripe status
    def self.valid_stripe_status?(status)
      ALL_STRIPE_STATUSES.include?(status)
    end
  end
end