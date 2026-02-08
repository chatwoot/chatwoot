import { ref, onBeforeUnmount } from 'vue';

export const useLiveRefresh = (callback, interval = 60000) => {
  const timeoutId = ref(null);

  const startRefetching = () => {
    timeoutId.value = setTimeout(async () => {
      await callback();
      startRefetching();
    }, interval);
  };

  const stopRefetching = () => {
    if (timeoutId.value) {
      clearTimeout(timeoutId.value);
      timeoutId.value = null;
    }
  };

  onBeforeUnmount(() => {
    stopRefetching();
  });

  return {
    startRefetching,
    stopRefetching,
  };
};
