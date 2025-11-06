import { computed, unref } from 'vue';

export function useVoiceCallStatus(statusRef, directionRef) {
  const status = computed(() => unref(statusRef)?.toString());
  const direction = computed(() => unref(directionRef)?.toString());

  const isOutbound = computed(() => direction.value === 'outbound');
  const isFailed = computed(() =>
    ['no-answer', 'failed'].includes(status.value)
  );

  const labelKey = computed(() => {
    switch (status.value) {
      case 'in-progress':
        return 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS';
      case 'ringing':
        return isOutbound.value
          ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
          : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
      case 'completed':
        return 'CONVERSATION.VOICE_CALL.CALL_ENDED';
      default:
        return isFailed.value
          ? 'CONVERSATION.VOICE_CALL.MISSED_CALL'
          : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
    }
  });

  const subtextKey = computed(() => {
    switch (status.value) {
      case 'ringing':
        return 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
      case 'in-progress':
        return isOutbound.value
          ? 'CONVERSATION.VOICE_CALL.THEY_ANSWERED'
          : 'CONVERSATION.VOICE_CALL.YOU_ANSWERED';
      case 'completed':
        return 'CONVERSATION.VOICE_CALL.CALL_ENDED';
      default:
        return isFailed.value
          ? 'CONVERSATION.VOICE_CALL.NO_ANSWER'
          : 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
    }
  });

  const defaultIcon = computed(() =>
    isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming'
  );

  const bubbleIconName = computed(() => {
    if (status.value === 'in-progress') {
      return 'i-ph-phone-call';
    }
    if (isFailed.value) {
      return 'i-ph-phone-x';
    }
    return defaultIcon.value;
  });

  const bubbleIconBg = computed(() => {
    if (status.value === 'in-progress') {
      return 'bg-n-teal-9';
    }
    if (isFailed.value) {
      return 'bg-n-ruby-9';
    }
    if (status.value === 'completed') {
      return 'bg-n-slate-11';
    }
    return 'bg-n-teal-9 animate-pulse';
  });

  const bubbleIconText = computed(() => {
    if (isFailed.value) {
      return 'text-white';
    }
    if (status.value === 'completed') {
      return 'text-n-slate-1';
    }
    return 'text-white';
  });

  const listIconColor = computed(() => {
    if (['in-progress', 'ringing'].includes(status.value)) {
      return 'text-n-teal-9';
    }
    if (isFailed.value) {
      return 'text-n-ruby-9';
    }
    if (status.value === 'completed') {
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
