/**
 * @file useUnreadTabBadge.js
 * @description Keeps the browser tab in sync with the unread notification
 * count: a numbered red badge on the favicon and a `(N) ` prefix on the title.
 * The watcher is set up automatically, so calling the composable is enough.
 */

import { watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { setUnreadCount } from 'dashboard/helper/unreadBadgeHelper';

export function useUnreadTabBadge() {
  const unreadCount = useMapGetter('notifications/getUnreadCount');

  watch(unreadCount, count => setUnreadCount(count), { immediate: true });

  return { unreadCount };
}
