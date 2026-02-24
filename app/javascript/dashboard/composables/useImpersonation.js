import { computed } from 'vue';
import SessionStorage from 'shared/helpers/sessionStorage';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';

export function useImpersonation() {
  const isImpersonating = computed(() => {
    return SessionStorage.get(SESSION_STORAGE_KEYS.IMPERSONATION_USER);
  });
  return { isImpersonating };
}
