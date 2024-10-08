import { computed } from 'vue';
import { useRoute } from 'vue-router';

export function useAccountId() {
  const route = useRoute();

  return computed(() => {
    return Number(route.params.accountId);
  });
}
