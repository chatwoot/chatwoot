import { computed, unref } from 'vue';

export function useVoiceCallStatus(statusRef, directionRef) {
  const status = computed(() => (unref(statusRef) || '').toString());
  const direction = computed(() => (unref(directionRef) || '').toString());

  const labelKey = computed(() => {
    const s = status.value;
    if (s === 'in-progress') {
      return direction.value === 'outbound'
        ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
        : 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS';
    }
    if (s === 'ringing') {
      return direction.value === 'outbound'
        ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
        : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
    }
    if (s === 'no-answer') return 'CONVERSATION.VOICE_CALL.MISSED_CALL';
    if (s === 'busy' || s === 'failed')
      return 'CONVERSATION.VOICE_CALL.NO_ANSWER';
    if (s === 'completed' || s === 'canceled')
      return 'CONVERSATION.VOICE_CALL.CALL_ENDED';
    return 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
  });

  const subtextKey = computed(() => {
    const s = status.value;
    if (s === 'ringing') return 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
    if (s === 'in-progress') {
      return direction.value === 'outbound'
        ? 'CONVERSATION.VOICE_CALL.THEY_ANSWERED'
        : 'CONVERSATION.VOICE_CALL.YOU_ANSWERED';
    }
    if (s === 'no-answer' || s === 'busy' || s === 'failed')
      return 'CONVERSATION.VOICE_CALL.NO_ANSWER';
    if (s === 'completed' || s === 'canceled')
      return 'CONVERSATION.VOICE_CALL.CALL_ENDED';
    return 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
  });

  // Bubble (Phosphor) icon names and backgrounds (Tailwind classes)
  const bubbleIconName = computed(() => {
    const s = status.value;
    if (s === 'in-progress') {
      return direction.value === 'outbound'
        ? 'i-ph-phone-outgoing-fill'
        : 'i-ph-phone-incoming-fill';
    }
    if (s === 'no-answer' || s === 'busy' || s === 'failed')
      return 'i-ph-phone-x-fill';
    // For ringing/completed/canceled show direction when possible
    return direction.value === 'outbound'
      ? 'i-ph-phone-outgoing-fill'
      : 'i-ph-phone-incoming-fill';
  });

  const bubbleIconBg = computed(() => {
    const s = status.value;
    if (s === 'in-progress') return 'bg-green-500';
    if (s === 'no-answer' || s === 'busy' || s === 'failed')
      return 'bg-red-500';
    if (s === 'completed' || s === 'canceled') return 'bg-purple-500';
    // ringing or initiated
    return 'bg-green-500 animate-pulse';
  });

  // List (FluentIcon) icon names and colors
  const listIconName = computed(() => {
    const s = status.value;
    if (s === 'no-answer' || s === 'busy' || s === 'failed') return 'dismiss';
    return direction.value === 'outbound' ? 'call-outbound' : 'call-inbound';
  });

  const listIconColor = computed(() => {
    const s = status.value;
    if (s === 'in-progress' || s === 'ringing' || s === 'initiated')
      return 'text-n-teal-9';
    if (s === 'no-answer' || s === 'busy' || s === 'failed')
      return 'text-n-ruby-9';
    if (s === 'completed' || s === 'canceled') return 'text-n-slate-11';
    return 'text-n-teal-9';
  });

  return {
    status,
    labelKey,
    subtextKey,
    bubbleIconName,
    bubbleIconBg,
    listIconName,
    listIconColor,
  };
}
