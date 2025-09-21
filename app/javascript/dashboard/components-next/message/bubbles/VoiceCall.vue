<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from '../provider.js';
import { useVoiceCallStatus } from 'dashboard/composables/useVoiceCallStatus';
import { useCallSession } from 'dashboard/composables/useCallSession';
import { MESSAGE_TYPES } from 'dashboard/components-next/message/constants.js';

const { contentAttributes, conversationId, inboxId, messageType } =
  useMessageContext();
const { joinCall, isJoining } = useCallSession();

const data = computed(() => contentAttributes.value?.data);

const status = computed(() => data.value?.status);
const direction = computed(() => {
  const dir = data.value?.call_direction;
  if (dir) return dir;
  const mt = messageType?.value;
  if (mt === MESSAGE_TYPES.OUTGOING) return 'outbound';
  if (mt === MESSAGE_TYPES.INCOMING) return 'inbound';
  return undefined;
});

const { labelKey, subtextKey, bubbleIconBg, bubbleIconName } =
  useVoiceCallStatus(status, direction);

const containerRingClass = computed(() => {
  return status.value === 'ringing' ? 'ring-1 ring-emerald-300' : '';
});

// Make join available whenever the call is ringing
const isJoinable = computed(() => status.value === 'ringing');

const joinConference = async () => {
  if (!isJoinable.value || isJoining.value) return null;
  try {
    const result = await joinCall({
      conversationId: conversationId.value,
      inboxId: inboxId.value,
      callSid: contentAttributes.value?.data?.call_sid,
      callMeta: data.value ? { ...data.value } : {},
    });

    if (result) {
      try {
        if (typeof window.stopAudioAlert === 'function')
          window.stopAudioAlert();
      } catch (_error) {
        // Ignore audio stop errors
      }
    }
    return result;
  } catch (_error) {
    return null;
  }
};
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div
      class="flex overflow-hidden flex-col w-full max-w-xs bg-white rounded-lg border border-slate-100 text-slate-900 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
      :class="[containerRingClass, { 'cursor-pointer': isJoinable }]"
      :tabindex="isJoinable ? 0 : -1"
      :role="isJoinable ? 'button' : 'article'"
      :aria-label="isJoinable ? $t('CONVERSATION.VOICE_CALL.JOIN_CALL') : ''"
      :title="isJoinable ? $t('CONVERSATION.VOICE_CALL.JOIN_CALL') : ''"
      @click.prevent.stop="joinConference"
      @keydown.enter.prevent.stop="joinConference"
      @keydown.space.prevent.stop="joinConference"
    >
      <div class="flex gap-3 items-center p-3 w-full">
        <div
          class="flex justify-center items-center rounded-full size-10 shrink-0"
          :class="bubbleIconBg"
        >
          <span class="text-xl" :class="bubbleIconName" />
        </div>

        <div class="flex overflow-hidden flex-col flex-grow">
          <span class="text-base font-medium truncate">{{ $t(labelKey) }}</span>
          <span class="text-xs text-slate-500">{{ $t(subtextKey) }}</span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
