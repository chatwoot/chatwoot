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

  const getRefreshDependencies = () => {
    const currentChat = unref(chat) || {};
    const currentAppliedSla = unref(appliedSla) || {};
    const currentSlaEvents = unref(slaEvents) || [];

    return [
      currentChat.status,
      currentChat.firstReplyCreatedAt ?? currentChat.first_reply_created_at,
      currentChat.waitingSince ?? currentChat.waiting_since,
      currentAppliedSla.slaStatus ?? currentAppliedSla.sla_status,
      currentAppliedSla.slaCompletedAt ?? currentAppliedSla.sla_completed_at,
      currentAppliedSla.slaFrtDueAt ?? currentAppliedSla.sla_frt_due_at,
      currentAppliedSla.slaNrtDueAt ?? currentAppliedSla.sla_nrt_due_at,
      currentAppliedSla.slaRtDueAt ?? currentAppliedSla.sla_rt_due_at,
      currentSlaEvents
        .map(
          event =>
            `${event.eventType ?? event.event_type}:${event.createdAt ?? event.created_at}`
        )
        .join('|'),
    ];
  };

  onMounted(refreshSlaStatus);
  onUnmounted(clearTimer);
  watch(getRefreshDependencies, refreshSlaStatus);

  return {
    slaStatus,
  };
};
