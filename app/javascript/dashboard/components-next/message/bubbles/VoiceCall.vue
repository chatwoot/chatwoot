<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { isInbound } from 'dashboard/helper/voice';

const props = defineProps({
  message: { type: Object, default: () => ({}) },
});

const { t } = useI18n();

const callData = computed(() => props.message?.contentAttributes?.data || {});


const isIncoming = computed(() => isInbound(callData.value?.call_direction));

// Determine status using Twilio-native values when available
const status = computed(() => {
  const cStatus = props.message?.conversation?.additional_attributes?.call_status;
  if (cStatus) return cStatus;

  const dStatus = callData.value?.status;
  if (dStatus) return dStatus;

  // Default to ringing when status is not yet set
  return 'ringing';
});

const iconName = computed(() => {
  if (['no-answer'].includes(status.value))
    return 'i-ph-phone-x-fill';
  if (status.value === 'in-progress') return 'i-ph-phone-call-fill';
  if (['completed', 'canceled'].includes(status.value))
    return isIncoming.value
      ? 'i-ph-phone-incoming-fill'
      : 'i-ph-phone-outgoing-fill';
  return isIncoming.value
    ? 'i-ph-phone-incoming-fill'
    : 'i-ph-phone-outgoing-fill';
});

const iconBgClass = computed(() => {
  if (status.value === 'in-progress') return 'bg-green-500';
  if (['no-answer'].includes(status.value)) return 'bg-red-500';
  if (['completed', 'canceled'].includes(status.value)) return 'bg-purple-500';
  // Ringing default with subtle pulse
  return 'bg-green-500 animate-pulse';
});

const labelText = computed(() => {
  if (status.value === 'in-progress')
    return t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
  if (isIncoming.value) {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
    if (status.value === 'no-answer')
      return t('CONVERSATION.VOICE_CALL.MISSED_CALL');
    if (['completed', 'canceled'].includes(status.value))
      return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
  } else {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
    if (status.value === 'no-answer' || status.value === 'busy' || status.value === 'failed')
      return t('CONVERSATION.VOICE_CALL.NO_ANSWER');
    if (['completed', 'canceled'].includes(status.value))
      return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
  }
  return isIncoming.value
    ? t('CONVERSATION.VOICE_CALL.INCOMING_CALL')
    : t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
});

const subtext = computed(() => {
  const attrs = props.message?.conversation?.additional_attributes || {};
  if (isIncoming.value) {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
    if (status.value === 'in-progress')
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
    if (status.value === 'no-answer')
      return t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER');
    if (['completed', 'canceled'].includes(status.value))
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
  } else {
    if (status.value === 'ringing')
      return t('CONVERSATION.VOICE_CALL.YOU_CALLED');
    if (status.value === 'in-progress')
      return t('CONVERSATION.VOICE_CALL.THEY_ANSWERED');
    if (['no-answer', 'completed', 'canceled', 'busy', 'failed'].includes(status.value))
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
