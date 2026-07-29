import { onMounted, onUnmounted, ref, unref, watch } from 'vue';
import {
  evaluateSLAStatus,
  shouldRefreshSLAStatus,
} from 'dashboard/helper/slaHelper';

const REFRESH_INTERVAL = 60000;

export const useSlaStatus = ({ appliedSla, chat, slaEvents }) => {
  const timer = ref(null);
  const slaStatus = ref({
    threshold: null,
    isSlaMissed: false,
    type: null,
    icon: null,
  });

  const updateSlaStatus = () => {
    slaStatus.value = evaluateSLAStatus({
      appliedSla: unref(appliedSla),
      chat: unref(chat),
      slaEvents: unref(slaEvents) || [],
    });
  };

  const clearTimer = () => {
    if (timer.value) {
      clearTimeout(timer.value);
      timer.value = null;
    }
  };

  const createTimer = () => {
    clearTimer();
    if (
      !shouldRefreshSLAStatus({
        appliedSla: unref(appliedSla),
        chat: unref(chat),
      })
    ) {
      return;
    }

    timer.value = setTimeout(() => {
      updateSlaStatus();
      createTimer();
    }, REFRESH_INTERVAL);
  };

  const refreshSlaStatus = () => {
    updateSlaStatus();
    createTimer();
  };

  onMounted(refreshSlaStatus);
  onUnmounted(clearTimer);
  watch(() => unref(chat), refreshSlaStatus);

  return {
    slaStatus,
  };
};
