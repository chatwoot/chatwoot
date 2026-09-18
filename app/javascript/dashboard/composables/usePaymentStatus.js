import { computed } from 'vue';
import { useAccount } from './useAccount';
import { useAdmin } from './useAdmin';

export function usePaymentStatus() {
  const { accountId, currentAccount, isOnChatwootCloud } = useAccount();
  const { isAdmin: canManagePayment } = useAdmin();

  const isPastDue = computed(
    () =>
      isOnChatwootCloud.value &&
      currentAccount.value?.billing_provider === 'stripe' &&
      currentAccount.value?.custom_attributes?.subscription_status ===
        'past_due'
  );

  return { accountId, isPastDue, canManagePayment };
}
