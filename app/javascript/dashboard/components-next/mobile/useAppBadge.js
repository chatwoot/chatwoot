import { watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

// Badging API: iOS 16.4+ (PWA instalado) e Chrome/Android. No-op fora disso.
const canBadge = () =>
  typeof navigator !== 'undefined' && 'setAppBadge' in navigator;

export const useAppBadge = () => {
  if (!canBadge()) return;
  const unreadCount = useMapGetter('notifications/getUnreadCount');
  watch(
    unreadCount,
    count => {
      if (count > 0) navigator.setAppBadge(count).catch(() => {});
      else navigator.clearAppBadge().catch(() => {});
    },
    { immediate: true }
  );
};

export default useAppBadge;
