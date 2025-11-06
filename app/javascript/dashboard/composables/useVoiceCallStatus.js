import { computed, unref } from 'vue';

const CALL_STATUSES = {
  IN_PROGRESS: 'in-progress',
  RINGING: 'ringing',
  COMPLETED: 'completed',
  NO_ANSWER: 'no-answer',
  FAILED: 'failed',
};

const CALL_DIRECTIONS = {
  INBOUND: 'inbound',
  OUTBOUND: 'outbound',
};

/**
 * Composable for handling voice call status display logic
 * @param {Ref|string} statusRef - Call status (ringing, in-progress, etc.)
 * @param {Ref|string} directionRef - Call direction (inbound, outbound)
 * @returns {Object} UI properties for displaying call status
 */
export function useVoiceCallStatus(statusRef, directionRef) {
  const status = computed(() => unref(statusRef)?.toString());
  const direction = computed(() => unref(directionRef)?.toString());

  // Status group helpers
  const isFailedStatus = computed(() =>
    [CALL_STATUSES.NO_ANSWER, CALL_STATUSES.FAILED].includes(status.value)
  );
  const isCompleted = computed(() => status.value === CALL_STATUSES.COMPLETED);
  const isOutbound = computed(
    () => direction.value === CALL_DIRECTIONS.OUTBOUND
  );

  const labelKey = computed(() => {
    const s = status.value;

    if (s === CALL_STATUSES.IN_PROGRESS) {
      return 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS';
    }

    if (s === CALL_STATUSES.RINGING) {
      return isOutbound.value
        ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
        : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
    }

    if (isFailedStatus.value) {
      return 'CONVERSATION.VOICE_CALL.MISSED_CALL';
    }

    if (isCompleted.value) {
      return 'CONVERSATION.VOICE_CALL.CALL_ENDED';
    }

    return 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
  });

  const subtextKey = computed(() => {
    const s = status.value;

    if (s === CALL_STATUSES.RINGING) {
      return 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
    }

    if (s === CALL_STATUSES.IN_PROGRESS) {
      return isOutbound.value
        ? 'CONVERSATION.VOICE_CALL.THEY_ANSWERED'
        : 'CONVERSATION.VOICE_CALL.YOU_ANSWERED';
    }

    return 'CONVERSATION.VOICE_CALL.NO_ANSWER';
  });

  const bubbleIconName = computed(() => {
    const s = status.value;

    if (s === CALL_STATUSES.IN_PROGRESS) {
      return 'i-ph-phone-call';
    }

    if (isFailedStatus.value) {
      return 'i-ph-phone-x';
    }

    if (isCompleted.value) {
      return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
    }

    return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
  });

  const bubbleIconBg = computed(() => {
    const s = status.value;

    if (s === CALL_STATUSES.IN_PROGRESS) {
      return 'bg-n-teal-9';
    }

    if (isFailedStatus.value) {
      return 'bg-n-ruby-9';
    }

    if (isCompleted.value) {
      return 'bg-n-slate-11';
    }

    // default (e.g., ringing)
    return 'bg-n-teal-9 animate-pulse';
  });

  const bubbleIconText = computed(() => {
    if (isFailedStatus.value) {
      return 'text-white';
    }

    if (isCompleted.value) {
      return 'text-n-slate-1';
    }

    return 'text-white';
  });

  const listIconColor = computed(() => {
    const s = status.value;

    if (s === CALL_STATUSES.IN_PROGRESS || s === CALL_STATUSES.RINGING) {
      return 'text-n-teal-9';
    }

    if (isFailedStatus.value) {
      return 'text-n-ruby-9';
    }

    if (isCompleted.value) {
      return 'text-n-slate-11';
    }

    return 'text-n-teal-9';
  });

  return {
    status,
    labelKey,
    subtextKey,
    bubbleIconName,
    bubbleIconBg,
    bubbleIconText,
    listIconColor,
  };
}
