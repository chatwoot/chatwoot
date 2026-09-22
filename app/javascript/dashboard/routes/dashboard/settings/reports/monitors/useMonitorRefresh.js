import { onMounted, onBeforeUnmount } from 'vue';
import { useEventListener, useIntervalFn, useThrottleFn } from '@vueuse/core';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const REFRESH_INTERVAL_MS = 30000;
const REFRESH_THROTTLE_MS = 2000;

export function useMonitorRefresh(refresh) {
  let isMounted = false;
  const visibleRefresh = () => {
    if (isMounted && document.visibilityState === 'visible') refresh();
  };
  const throttledRefresh = useThrottleFn(
    visibleRefresh,
    REFRESH_THROTTLE_MS,
    true
  );
  useIntervalFn(visibleRefresh, REFRESH_INTERVAL_MS);
  useEventListener(window, 'focus', throttledRefresh);
  useEventListener(document, 'visibilitychange', throttledRefresh);
  const events = [BUS_EVENTS.MONITOR_UPDATED, BUS_EVENTS.WEBSOCKET_RECONNECT];
  onMounted(() => {
    isMounted = true;
    events.forEach(event => emitter.on(event, throttledRefresh));
  });
  onBeforeUnmount(() => {
    isMounted = false;
    events.forEach(event => emitter.off(event, throttledRefresh));
  });
}
