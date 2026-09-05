import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

export function useRestrictedAgent() {
  const currentUser = useMapGetter('getCurrentUser');
  const currentAccountId = useMapGetter('getCurrentAccountId');

  const isRestrictedAgent = computed(() => {
    const account = currentUser.value?.accounts?.find(
      item => Number(item.id) === Number(currentAccountId.value)
    );

    return account?.role === 'agent' && !account?.custom_role_id;
  });

  const canExportData = computed(() => !isRestrictedAgent.value);

  return {
    isRestrictedAgent,
    canExportData,
  };
}
