<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { normalizeStatus, isInbound } from 'dashboard/helper/voice';

const props = defineProps({
  message: { type: Object, default: () => ({}) },
});

const { t } = useI18n();

const callData = computed(() => props.message?.contentAttributes?.data || {});


const isIncoming = computed(() => {
  const direction = callData.value?.call_direction;
  return isInbound(direction, props.message?.messageType);
});

const status = computed(() => {
  const cStatus =
    props.message?.conversation?.additional_attributes?.call_status;
  if (cStatus) return normalizeStatus(cStatus);

  const dStatus = callData.value?.status;
  if (dStatus) return normalizeStatus(dStatus);

  if (callData.value?.ended_at) return 'ended';
  if (callData.value?.missed) return isIncoming.value ? 'missed' : 'no_answer';

  if (
    callData.value?.started_at ||
    props.message?.conversation?.additional_attributes?.call_started_at
  ) {
    return 'in_progress';
  }
  return 'ringing';
});

const iconName = computed(() => {
  if (['missed', 'no_answer'].includes(status.value))
    return 'i-ph-phone-x-fill';
  if (status.value === 'in_progress') return 'i-ph-phone-call-fill';
  if (status.value === 'ended')
    return isIncoming.value
      ? 'i-ph-phone-incoming-fill'
      : 'i-ph-phone-outgoing-fill';
  return isIncoming.value
    ? 'i-ph-phone-incoming-fill'
    : 'i-ph-phone-outgoing-fill';
});

const iconBgClass = computed(() => {
  if (status.value === 'in_progress') return 'bg-green-500';
  if (['missed', 'no_answer'].includes(status.value)) return 'bg-red-500';
  if (status.value === 'ended') return 'bg-purple-500';
  // Ringing default with subtle pulse
  return 'bg-green-500 animate-pulse';
});

const labelText = computed(() => {
  if (status.value === 'in_progress')
    return t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
  if (isIncoming.value) {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
    if (status.value === 'missed')
      return t('CONVERSATION.VOICE_CALL.MISSED_CALL');
    if (status.value === 'ended')
      return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
  } else {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
    if (status.value === 'no_answer')
      return t('CONVERSATION.VOICE_CALL.NO_ANSWER');
    if (status.value === 'ended')
      return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
  }
  return isIncoming.value
    ? t('CONVERSATION.VOICE_CALL.INCOMING_CALL')
    : t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
});

const subtext = computed(() => {
  const attrs = props.message?.conversation?.additional_attributes || {};
  const agentJoined = attrs?.agent_joined === true;
  const callStarted = !!attrs?.call_started_at;
  if (isIncoming.value) {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
    if (status.value === 'in_progress')
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
    if (status.value === 'missed' && (agentJoined || callStarted))
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
    if (status.value === 'missed')
      return t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER');
    if (status.value === 'ended')
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
  } else {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.YOU_CALLED');
    if (status.value === 'in_progress')
      return t('CONVERSATION.VOICE_CALL.THEY_ANSWERED');
    if (['no_answer', 'ended'].includes(status.value))
      return t('CONVERSATION.VOICE_CALL.YOU_CALLED');
  }
  return isIncoming.value
    ? t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER')
    : t('CONVERSATION.VOICE_CALL.YOU_CALLED');
});

const containerRingClass = computed(() => {
  // Add a subtle ring effect for ringing state without custom CSS
  return status.value === 'ringing' ? 'ring-1 ring-emerald-300' : '';
});
</script>

<template>
  <div
    class="flex w-full max-w-xs flex-col overflow-hidden rounded-lg border border-slate-100 bg-white text-slate-900 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
    :class="containerRingClass"
  >
    <div class="flex w-full items-center gap-3 p-3">
      <div
        class="size-10 shrink-0 flex items-center justify-center rounded-full text-white"
        :class="iconBgClass"
      >
        <span class="text-xl" :class="[iconName]" />
      </div>

      <div class="flex flex-grow flex-col overflow-hidden">
        <span class="truncate text-base font-medium">{{ labelText }}</span>
        <span class="text-xs text-slate-500">{{ subtext }}</span>
      </div>
    </div>
  </div>
</template>
