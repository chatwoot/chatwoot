<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import {
  ATTACHMENT_TYPES,
  MESSAGE_TYPES,
  VOICE_CALL_STATUS,
} from '../constants';
import { formatDuration } from 'shared/helpers/timeHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useCallSession } from 'dashboard/composables/useCallSession';

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

const { t } = useI18n();
const store = useStore();
const { activeCall, hasActiveCall, isJoining, joinCall, endCall } =
  useCallSession({
    manageSessionState: false,
  });
const {
  attachments,
  contentAttributes,
  conversationId,
  currentUserId,
  inboxId,
  messageType,
} = useMessageContext();

const JOINABLE_STATUSES = [
  VOICE_CALL_STATUS.RINGING,
  VOICE_CALL_STATUS.IN_PROGRESS,
];

const data = computed(() => contentAttributes.value?.data);
const status = computed(() => data.value?.status?.toString());
const callSid = computed(() => {
  return (data.value?.callSid || data.value?.call_sid || '').toString();
});
const joinedBy = computed(() => {
  return data.value?.meta?.joinedBy || data.value?.meta?.joined_by;
});
const callDuration = computed(() => {
  return data.value?.meta?.duration;
});
const recordingAttachment = computed(() => {
  return attachments.value?.find(
    attachment => attachment.fileType === ATTACHMENT_TYPES.AUDIO
  );
});
const conversation = computed(() => {
  return store.getters.getConversationById?.(conversationId.value) || null;
});
const activeConversation = computed(() => {
  const activeConversationId = activeCall.value?.conversationId;
  if (!activeConversationId) return null;

  return store.getters.getConversationById?.(activeConversationId) || null;
});
const assigneeId = computed(() => {
  return (
    conversation.value?.meta?.assignee?.id || conversation.value?.assignee_id
  );
});

const isOutbound = computed(() => messageType.value === MESSAGE_TYPES.OUTGOING);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);
const didCurrentUserAnswer = computed(() => {
  return joinedBy.value?.id === currentUserId.value;
});

const label = computed(() => {
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
  }

  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
  }

  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? t('CONVERSATION.VOICE_CALL.OUTGOING_CALL')
      : t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
  }

  return isFailed.value
    ? t('CONVERSATION.VOICE_CALL.MISSED_CALL')
    : t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
});

const subtext = computed(() => {
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
  }

  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return (
      formatDuration(callDuration.value) ||
      t('CONVERSATION.VOICE_CALL.CALL_ENDED')
    );
  }

  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    if (didCurrentUserAnswer.value) {
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
    }

    if (joinedBy.value?.name) {
      return t('CONVERSATION.VOICE_CALL.AGENT_ANSWERED', {
        agentName: joinedBy.value.name,
      });
    }

    return t('CONVERSATION.VOICE_CALL.THEY_ANSWERED');
  }

  return isFailed.value
    ? t('CONVERSATION.VOICE_CALL.NO_ANSWER')
    : t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
});

const iconName = computed(() => {
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
});

const bgColor = computed(() => BG_COLOR_MAP[status.value] || 'bg-n-teal-9');
const resolvedInboxId = computed(() => {
  return inboxId.value || conversation.value?.inbox_id || null;
});
const isCurrentActiveCall = computed(() => {
  return activeCall.value?.callSid === callSid.value;
});
const canJoinCall = computed(() => {
  return (
    JOINABLE_STATUSES.includes(status.value) &&
    !!conversationId.value &&
    !!resolvedInboxId.value &&
    !!callSid.value &&
    (!assigneeId.value || assigneeId.value === currentUserId.value) &&
    !isCurrentActiveCall.value
  );
});
const joinCallText = computed(() => {
  return status.value === VOICE_CALL_STATUS.IN_PROGRESS
    ? t('CONVERSATION.VOICE_CALL.REJOIN_CALL')
    : t('CONVERSATION.VOICE_CALL.JOIN_CALL');
});

const handleJoinCall = async () => {
  if (!canJoinCall.value || isJoining.value) return;

  if (hasActiveCall.value) {
    if (activeCall.value?.callSid === callSid.value) return;

    const activeInboxId = activeConversation.value?.inbox_id;
    if (activeCall.value?.conversationId && activeInboxId) {
      await endCall({
        conversationId: activeCall.value.conversationId,
        inboxId: activeInboxId,
      });
    }
  }

  await joinCall({
    conversationId: conversationId.value,
    inboxId: resolvedInboxId.value,
    callSid: callSid.value,
  });
};
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div class="flex overflow-hidden flex-col w-full max-w-sm">
      <button
        class="flex gap-3 items-center p-3 w-full text-left border-none bg-transparent"
        :class="{
          'cursor-pointer transition-colors hover:bg-n-alpha-1 active:bg-n-alpha-2':
            canJoinCall,
          'cursor-default': !canJoinCall,
        }"
        :disabled="!canJoinCall || isJoining"
        data-test-id="voice-call-join"
        type="button"
        @click="handleJoinCall"
      >
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

        <div class="flex overflow-hidden flex-col flex-grow">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ label }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{ subtext }}
          </span>
          <span
            v-if="canJoinCall"
            class="mt-1 text-xs font-medium text-n-teal-10"
          >
            {{ joinCallText }}
          </span>
        </div>
      </button>
      <div v-if="recordingAttachment" class="px-3 pb-3">
        <AudioChip class="text-n-slate-12" :attachment="recordingAttachment" />
      </div>
    </div>
  </BaseBubble>
</template>
