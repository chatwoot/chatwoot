// Subscription status constants matching backend Billing::SubscriptionStatuses
// These should be kept in sync with lib/billing/subscription_statuses.rb

// Stripe subscription statuses
export const SUBSCRIPTION_STATUSES = {
  ACTIVE: 'active',
  CANCELED: 'canceled',
  INCOMPLETE: 'incomplete',
  INCOMPLETE_EXPIRED: 'incomplete_expired',
  PAST_DUE: 'past_due',
  TRIALING: 'trialing',
  UNPAID: 'unpaid',
  PAUSED: 'paused',

  // Application-specific statuses
  INACTIVE: 'inactive',
};

// Status groups for easier filtering
export const PAID_STATUSES = [
  SUBSCRIPTION_STATUSES.ACTIVE,
  SUBSCRIPTION_STATUSES.TRIALING,
];

export const FAILED_PAYMENT_STATUSES = [
  SUBSCRIPTION_STATUSES.PAST_DUE,
  SUBSCRIPTION_STATUSES.CANCELED,
  SUBSCRIPTION_STATUSES.UNPAID,
];

// Helper functions
export const isPaidStatus = status => PAID_STATUSES.includes(status);
export const isFailedPaymentStatus = status =>
  FAILED_PAYMENT_STATUSES.includes(status);
export const shouldShowBanner = status =>
  [SUBSCRIPTION_STATUSES.PAST_DUE, SUBSCRIPTION_STATUSES.INACTIVE].includes(
    status
  );
