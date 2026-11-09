import { computed } from 'vue';
import { useAccount } from './useAccount';
import { useAdmin } from './useAdmin';
import { useMapGetter } from './store';

export function usePaymentStatus() {
  const { accountId, currentAccount, isOnChatwootCloud } = useAccount();
  const { isAdmin } = useAdmin();
  const currentUser = useMapGetter('getCurrentUser');

  const isPastDue = computed(() => {
    if (!isOnChatwootCloud.value) {
      return (
        currentAccount.value?.installation_subscription_status === 'past_due'
      );
    }
    return (
      currentAccount.value?.billing_provider === 'stripe' &&
      currentAccount.value?.custom_attributes?.subscription_status ===
        'past_due'
    );
  });

  const canManagePayment = computed(() =>
    isOnChatwootCloud.value
      ? isAdmin.value
      : currentUser.value.type === 'SuperAdmin'
  );

  return { accountId, isPastDue, canManagePayment, isOnChatwootCloud };
}
