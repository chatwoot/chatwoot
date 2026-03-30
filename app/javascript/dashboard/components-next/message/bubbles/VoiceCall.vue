<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMessageContext } from '../provider.js';
import { MESSAGE_TYPES, VOICE_CALL_STATUS } from '../constants';
import { acceptWhatsappCallById } from 'dashboard/composables/useWhatsappCallSession';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

const LABEL_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const SUBTEXT_MAP = {
  [VOICE_CALL_STATUS.RINGING]: 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-phone-call',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-phone-x',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-phone-x',
};

const BG_COLOR_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'bg-n-teal-9',
  [VOICE_CALL_STATUS.RINGING]: 'bg-n-teal-9 animate-pulse',
  [VOICE_CALL_STATUS.COMPLETED]: 'bg-n-slate-11',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'bg-n-ruby-9',
  [VOICE_CALL_STATUS.FAILED]: 'bg-n-ruby-9',
};

const router = useRouter();
const { contentAttributes, messageType } = useMessageContext();

// NOTE: contentAttributes.data keys are camelCase because MessageList.vue
// applies useCamelCase(messages, { deep: true }) before rendering.
const data = computed(() => contentAttributes.value?.data);
const status = computed(() => data.value?.status?.toString());

const isOutbound = computed(() => messageType.value === MESSAGE_TYPES.OUTGOING);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);

// Call source and metadata — all camelCase due to deep transform
const isWhatsappCall = computed(() => data.value?.callSource === 'whatsapp');
const waCallId = computed(() => data.value?.waCallId);
const acceptedBy = computed(() => data.value?.acceptedBy);
const durationSeconds = computed(() => data.value?.durationSeconds);
const recordingUrl = computed(() => data.value?.recordingUrl);
const transcript = computed(() => data.value?.transcript);
const isJoining = ref(false);
const showTranscript = ref(false);

const formattedDuration = computed(() => {
  const seconds = durationSeconds.value;
  if (!seconds || seconds <= 0) return '';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return mins > 0 ? `${mins}m ${secs}s` : `${secs}s`;
});

// Show join/accept button logic
// WhatsApp: only ringing (peer-to-peer WebRTC — cannot rejoin after accept)
// Twilio: ringing + in-progress (conference model supports rejoin)
const showJoinButton = computed(() => {
  if (isWhatsappCall.value) {
    return status.value === VOICE_CALL_STATUS.RINGING;
  }
  return [VOICE_CALL_STATUS.RINGING, VOICE_CALL_STATUS.IN_PROGRESS].includes(
    status.value
  );
});

const joinButtonLabel = computed(() => {
  if (isWhatsappCall.value && status.value === VOICE_CALL_STATUS.RINGING) {
    return 'CONVERSATION.VOICE_CALL.ACCEPT_CALL';
  }
  return 'CONVERSATION.VOICE_CALL.JOIN_CALL';
});

const labelKey = computed(() => {
  if (LABEL_MAP[status.value]) return LABEL_MAP[status.value];
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
      : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
  }
  return isFailed.value
    ? 'CONVERSATION.VOICE_CALL.MISSED_CALL'
    : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
});

const subtextKey = computed(() => {
  if (
    acceptedBy.value?.name &&
    [VOICE_CALL_STATUS.IN_PROGRESS, VOICE_CALL_STATUS.COMPLETED].includes(
      status.value
    )
  ) {
    return null;
  }

  if (SUBTEXT_MAP[status.value]) return SUBTEXT_MAP[status.value];
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.THEY_ANSWERED'
      : 'CONVERSATION.VOICE_CALL.YOU_ANSWERED';
  }
  return isFailed.value
    ? 'CONVERSATION.VOICE_CALL.NO_ANSWER'
    : 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
});

const answeredByText = computed(() => {
  if (!acceptedBy.value?.name) return '';
  return acceptedBy.value.name;
});

const iconName = computed(() => {
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
});

const bgColor = computed(() => BG_COLOR_MAP[status.value] || 'bg-n-teal-9');

const handleJoinCall = async () => {
  if (isJoining.value) return;
  isJoining.value = true;

  try {
    if (isWhatsappCall.value) {
      const result = await acceptWhatsappCallById(waCallId.value);
      if (result?.success && result.call) {
        router.push({
          name: 'inbox_conversation',
          params: { conversation_id: result.call.conversationId },
        });
      }
    }
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[WhatsApp Call] Accept from bubble failed:', err);
  } finally {
    isJoining.value = false;
  }
};
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div class="flex overflow-hidden flex-col w-full max-w-xs">
      <div class="flex gap-3 items-center p-3 w-full">
        <div
          class="flex justify-center items-center rounded-full size-10 shrink-0"
          :class="bgColor"
        >
          <Icon
            class="size-5"
            :icon="iconName"
            :class="{
              'text-n-slate-1': status === VOICE_CALL_STATUS.COMPLETED,
              'text-white': status !== VOICE_CALL_STATUS.COMPLETED,
            }"
          />
        </div>

        <div class="flex overflow-hidden flex-col flex-grow gap-0.5">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ $t(labelKey) }}
          </span>
          <span v-if="answeredByText" class="text-xs text-n-slate-11">
            {{
              $t('CONVERSATION.VOICE_CALL.ANSWERED_BY', {
                name: answeredByText,
              })
            }}
          </span>
          <span v-else-if="subtextKey" class="text-xs text-n-slate-11">
            {{ $t(subtextKey) }}
          </span>
          <span
            v-if="formattedDuration && status === VOICE_CALL_STATUS.COMPLETED"
            class="text-xs text-n-slate-10"
          >
            {{ formattedDuration }}
          </span>
        </div>

        <button
          v-if="showJoinButton"
          :disabled="isJoining"
          class="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-white bg-n-teal-9 hover:bg-n-teal-10 rounded-lg transition-colors shrink-0"
          :class="{ 'opacity-75 cursor-wait': isJoining }"
          @click="handleJoinCall"
        >
          <i
            v-if="isJoining"
            class="i-ph-circle-notch-bold text-sm animate-spin"
          />
          <i v-else class="i-ph-phone-bold text-sm" />
          {{ $t(joinButtonLabel) }}
        </button>
      </div>

      <div
        v-if="recordingUrl && status === VOICE_CALL_STATUS.COMPLETED"
        class="px-3 pb-2"
      >
        <audio controls class="w-full h-8" :src="recordingUrl">
          {{ $t('CONVERSATION.VOICE_CALL.AUDIO_NOT_SUPPORTED') }}
        </audio>
      </div>

      <div
        v-if="transcript && status === VOICE_CALL_STATUS.COMPLETED"
        class="px-3 pb-3"
      >
        <button
          class="flex items-center gap-1 text-xs text-n-slate-11 hover:text-n-slate-12 transition-colors"
          @click="showTranscript = !showTranscript"
        >
          <i
            class="text-sm"
            :class="
              showTranscript ? 'i-ph-caret-up-bold' : 'i-ph-caret-down-bold'
            "
          />
          {{ $t('CONVERSATION.VOICE_CALL.TRANSCRIPT') }}
        </button>
        <p
          v-if="showTranscript"
          class="mt-1 text-xs leading-relaxed text-n-slate-11 whitespace-pre-wrap"
        >
          {{ transcript }}
        </p>
      </div>
    </div>
  </BaseBubble>
</template>
