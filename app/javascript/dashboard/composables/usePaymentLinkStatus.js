import { computed, unref } from 'vue';

const PAYMENT_STATUSES = {
  INITIATED: 'initiated',
  PENDING: 'pending',
  PAID: 'paid',
  FAILED: 'failed',
  EXPIRED: 'expired',
  CANCELLED: 'cancelled',
};

/**
 * Composable for handling payment link status display logic
 * @param {Ref|string} statusRef - Payment status (initiated, pending, paid, failed, expired, cancelled)
 * @returns {Object} UI properties for displaying payment status
 */
export function usePaymentLinkStatus(statusRef) {
  const status = computed(() => unref(statusRef)?.toString() || 'initiated');

  const iconName = computed(() => {
    const s = status.value;

    if (s === PAYMENT_STATUSES.PAID) {
      return 'i-lucide-circle-check';
    }

    if (s === PAYMENT_STATUSES.FAILED) {
      return 'i-lucide-circle-x';
    }

    if (s === PAYMENT_STATUSES.EXPIRED) {
      return 'i-lucide-clock-alert';
    }

    if (s === PAYMENT_STATUSES.CANCELLED) {
      return 'i-lucide-ban';
    }

    if (s === PAYMENT_STATUSES.PENDING) {
      return 'i-lucide-circle-dot-dashed';
    }

    // Default for initiated
    return 'i-lucide-circle-dashed';
  });

  const iconBgColor = computed(() => {
    const s = status.value;

    if (s === PAYMENT_STATUSES.PAID) {
      return 'bg-n-teal-9';
    }

    if (s === PAYMENT_STATUSES.FAILED) {
      return 'bg-n-ruby-9';
    }

    if (s === PAYMENT_STATUSES.EXPIRED || s === PAYMENT_STATUSES.CANCELLED) {
      return 'bg-n-slate-11';
    }

    if (s === PAYMENT_STATUSES.PENDING) {
      return 'bg-n-amber-9';
    }

    // Default for initiated
    return 'bg-n-sky-9';
  });

  const labelKey = computed(() => {
    const s = status.value;

    if (s === PAYMENT_STATUSES.PAID) {
      return 'PAYMENT_LINK.STATUS.PAID';
    }

    if (s === PAYMENT_STATUSES.FAILED) {
      return 'PAYMENT_LINK.STATUS.FAILED';
    }

    if (s === PAYMENT_STATUSES.EXPIRED) {
      return 'PAYMENT_LINK.STATUS.EXPIRED';
    }

    if (s === PAYMENT_STATUSES.CANCELLED) {
      return 'PAYMENT_LINK.STATUS.CANCELLED';
    }

    if (s === PAYMENT_STATUSES.PENDING) {
      return 'PAYMENT_LINK.STATUS.PENDING';
    }

    return 'PAYMENT_LINK.STATUS.INITIATED';
  });

  const statusBadgeBg = computed(() => {
    const s = status.value;

    if (s === PAYMENT_STATUSES.PAID) {
      return 'bg-n-teal-4';
    }

    if (s === PAYMENT_STATUSES.FAILED) {
      return 'bg-n-ruby-4';
    }

    if (s === PAYMENT_STATUSES.EXPIRED || s === PAYMENT_STATUSES.CANCELLED) {
      return 'bg-n-slate-4';
    }

    if (s === PAYMENT_STATUSES.PENDING) {
      return 'bg-n-amber-4';
    }

    // Default for initiated
    return 'bg-n-sky-4';
  });

  const statusBadgeText = computed(() => {
    const s = status.value;

    if (s === PAYMENT_STATUSES.PAID) {
      return 'text-n-teal-11';
    }

    if (s === PAYMENT_STATUSES.FAILED) {
      return 'text-n-ruby-11';
    }

    if (s === PAYMENT_STATUSES.EXPIRED || s === PAYMENT_STATUSES.CANCELLED) {
      return 'text-n-slate-11';
    }

    if (s === PAYMENT_STATUSES.PENDING) {
      return 'text-n-amber-11';
    }

    // Default for initiated
    return 'text-n-sky-11';
  });

  return {
    status,
    iconName,
    iconBgColor,
    labelKey,
    statusBadgeBg,
    statusBadgeText,
  };
}
