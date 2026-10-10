import { onBeforeUnmount, toValue } from 'vue';
import { useEventListener, useIntervalFn, useThrottleFn } from '@vueuse/core';
import { useEmitter } from 'dashboard/composables/emitter';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const REFRESH_INTERVAL_MS = 30000;
const REFRESH_THROTTLE_MS = 2000;

export function useMonitorRefresh(
  refresh,
  { monitorId = null, onDeleted } = {}
) {
  // The throttle's trailing call can still fire after the page is gone.
  let isActive = true;
  const isVisible = () => document.visibilityState === 'visible';
  const refreshIfVisible = () => {
    if (isActive && isVisible()) refresh();
  };
  const throttledRefresh = useThrottleFn(
    refreshIfVisible,
    REFRESH_THROTTLE_MS,
    true
  );
  // Returning to the tab fires both focus and visibilitychange; refresh once.
  const refreshOnReturn = useThrottleFn(refresh, REFRESH_THROTTLE_MS);
  const onReturn = () => {
    if (isVisible()) refreshOnReturn();
  };

  useIntervalFn(refreshIfVisible, REFRESH_INTERVAL_MS);
  useEventListener(window, 'focus', onReturn);
  useEventListener(document, 'visibilitychange', onReturn);
  useEmitter(BUS_EVENTS.WEBSOCKET_RECONNECT, throttledRefresh);
  useEmitter(BUS_EVENTS.MONITOR_UPDATED, data => {
    const scopedId = toValue(monitorId);
    if (scopedId && data.monitor_id !== scopedId) return;
    if (scopedId && data.deleted && onDeleted) {
      onDeleted();
      return;
    }
    throttledRefresh();
  });
  onBeforeUnmount(() => {
    isActive = false;
  });
}
