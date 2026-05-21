<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMessageContext } from '../provider.js';
import { VOICE_CALL_STATUS, MESSAGE_TYPES } from '../constants';
import { useCallActions } from 'dashboard/composables/useCallSession';
import { useWhatsappCallSession } from 'dashboard/composables/useWhatsappCallSession';
import { useCallsStore } from 'dashboard/stores/calls';
import { formatDuration } from 'shared/helpers/timeHelper';
import { useAlert } from 'dashboard/composables';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';

const LABEL_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-phone-call-bold',
  [VOICE_CALL_STATUS.COMPLETED]: 'i-ph-phone-bold',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-phone-x-bold',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-phone-x-bold',
};

const { t } = useI18n();
const store = useStore();
const {
  call,
  attachments,
  contentAttributes,
  conversationId,
  currentUserId,
  inboxId,
  sender,
  messageType,
} = useMessageContext();
const { joinCall, endCall, activeCall, hasActiveCall, isJoining } =
  useCallActions();
const whatsappCallSession = useWhatsappCallSession();

const status = computed(() => call.value?.status);
// Server-side call records use `outgoing`/`incoming`, while the Pinia store
// and a few API hops normalise to `outbound`/`inbound`. Accept either so the
// bubble label matches the message orientation no matter the source.
const isOutbound = computed(() => {
  const dir = call.value?.direction;
  if (dir === 'outgoing' || dir === 'outbound') return true;
  if (dir === 'incoming' || dir === 'inbound') return false;
  // Fall back to the message orientation: agent-authored messages sit on the
  // right (outbound) and contact-authored ones on the left.
  return messageType.value === MESSAGE_TYPES.OUTGOING;
});
const isWhatsapp = computed(() => call.value?.provider === 'whatsapp');
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);
const isMissedInbound = computed(() => isFailed.value && !isOutbound.value);
const endReason = computed(() => call.value?.endReason);
const wasDeclinedByAgent = computed(
  () => isMissedInbound.value && endReason.value === 'agent_rejected'
);
const acceptedByAgentId = computed(() => call.value?.acceptedByAgentId);
const didCurrentUserAnswer = computed(
  () =>
    !!acceptedByAgentId.value && acceptedByAgentId.value === currentUserId.value
);
const conversationAssignee = computed(() => {
  const conversation = store.getters.getConversationById?.(
    conversationId?.value
  );
  return conversation?.meta?.assignee || null;
});
const displayAgentName = computed(() => {
  if (call.value?.acceptedByAgentName) return call.value.acceptedByAgentName;
  if (acceptedByAgentId.value) {
    const agent = store.getters['agents/getAgentById'](acceptedByAgentId.value);
    if (agent?.available_name) return agent.available_name;
    if (agent?.name) return agent.name;
  }
  return conversationAssignee.value?.name || null;
});

const audioAttachment = computed(() =>
  (attachments?.value || []).find(a => a.fileType === 'audio')
);

const durationSeconds = computed(() => {
  const fromCall = call.value?.durationSeconds || call.value?.duration_seconds;
  if (fromCall != null) return fromCall;
  const data = contentAttributes?.value?.data;
  return data?.durationSeconds || data?.duration_seconds;
});

const formattedDuration = computed(() => formatDuration(durationSeconds.value));

const labelKey = computed(() => {
  if (LABEL_MAP[status.value]) return LABEL_MAP[status.value];
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
      : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
  }
  if (isFailed.value) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.NO_ANSWER_OUTBOUND_LABEL'
      : 'CONVERSATION.VOICE_CALL.MISSED_CALL';
  }
  return 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
});

const subtext = computed(() => {
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? t('CONVERSATION.VOICE_CALL.CALLING')
      : t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
  }
  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return formattedDuration.value;
  }
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    if (isOutbound.value) return null;
    if (didCurrentUserAnswer.value) {
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
    }
    if (displayAgentName.value) {
      return t('CONVERSATION.VOICE_CALL.AGENT_ANSWERED', {
        agentName: displayAgentName.value,
      });
    }
    return null;
  }
  if (isFailed.value) {
    if (isOutbound.value) {
      return t('CONVERSATION.VOICE_CALL.NO_ANSWER_OUTBOUND_SUBTEXT');
    }
    if (wasDeclinedByAgent.value && displayAgentName.value) {
      return t('CONVERSATION.VOICE_CALL.MISSED_CALL_DECLINED_BY', {
        agentName: displayAgentName.value,
      });
    }
    return t('CONVERSATION.VOICE_CALL.MISSED_CALL_INBOUND_SUBTEXT');
  }
  return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
});

const iconName = computed(() => {
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value
    ? 'i-ph-phone-outgoing-bold'
    : 'i-ph-phone-incoming-bold';
});

// Subtle icon container — matches the design's tonal swatch over the bubble bg.
// Status drives the accent: teal for live, ruby for missed, neutral otherwise.
const iconContainerClass = computed(() => {
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return 'bg-n-teal-3 text-n-teal-11';
  }
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return 'bg-n-teal-3 text-n-teal-11';
  }
  if (isMissedInbound.value) {
    return 'bg-n-alpha-2 text-n-ruby-9';
  }
  return 'bg-n-alpha-2 text-n-slate-12';
});

const callSid = computed(() => call.value?.providerCallId);

const canJoinCall = computed(() => {
  if (status.value !== VOICE_CALL_STATUS.RINGING) return false;
  if (isOutbound.value) return false;
  if (acceptedByAgentId.value) return false;
  if (!callSid.value || !inboxId.value || !conversationId.value) return false;
  if (hasActiveCall.value && activeCall.value?.callSid === callSid.value)
    return false;
  const assignee = conversationAssignee.value;
  if (assignee?.id && assignee.id !== currentUserId.value) return false;
  return true;
});

const recordingAttachment = computed(() => {
  if (audioAttachment.value) return audioAttachment.value;
  const url = call.value?.recordingUrl;
  if (!url) return null;
  return {
    dataUrl: url,
    fileType: 'audio',
    extension: 'wav',
    transcribedText: call.value?.transcript || '',
  };
});

const handleJoinCall = async () => {
  if (!canJoinCall.value || isJoining.value) return;

  if (hasActiveCall.value && activeCall.value?.callSid !== callSid.value) {
    await endCall({
      conversationId: activeCall.value.conversationId,
      inboxId: activeCall.value.inboxId,
      callSid: activeCall.value.callSid,
    });
  }

  await joinCall({
    conversationId: conversationId.value,
    inboxId: inboxId.value,
    callSid: callSid.value,
  });
};

const canCallBack = computed(
  () => isMissedInbound.value && !!inboxId.value && !!conversationId.value
);

const handleCallBack = async () => {
  if (!canCallBack.value) return;
  try {
    if (isWhatsapp.value) {
      const response = await whatsappCallSession.initiateOutboundCall(
        conversationId.value
      );
      if (response?.status === 'locked') return;
      // Permission template path returns no call id — show banner, no widget yet.
      if (!response?.id) {
        useAlert(
          response?.status === 'permission_pending'
            ? t('CONVERSATION.HEADER.WHATSAPP_CALL_PERMISSION_PENDING')
            : t('CONVERSATION.HEADER.WHATSAPP_CALL_PERMISSION_REQUESTED')
        );
        return;
      }
      const callsStore = useCallsStore();
      callsStore.addCall({
        callSid: response.call_id,
        callId: response.id,
        conversationId: conversationId.value,
        inboxId: inboxId.value,
        callDirection: 'outbound',
        provider: 'whatsapp',
      });
      return;
    }
    await store.dispatch('contacts/initiateCall', {
      contactId: sender.value?.id,
      inboxId: inboxId.value,
      conversationId: conversationId.value,
    });
  } catch (error) {
    useAlert(error?.message || t('CONTACT_PANEL.CALL_FAILED'));
  }
};
</script>

<template>
  <BaseBubble class="!p-3 !max-w-md min-w-[240px]" hide-meta>
    <div class="flex flex-col gap-3 w-full">
      <!-- Header row: icon + title + duration/subtext -->
      <div class="flex gap-2.5 items-start">
        <div
          class="flex justify-center items-center rounded-xl size-11 shrink-0"
          :class="iconContainerClass"
        >
          <Icon class="size-4" :icon="iconName" />
        </div>
        <div class="flex flex-col flex-1 min-w-0 self-center">
          <span
            class="font-display text-sm font-medium leading-tight truncate tracking-tight"
          >
            {{ $t(labelKey) }}
          </span>
          <span
            v-if="subtext"
            class="text-sm leading-tight truncate tracking-tight opacity-75"
          >
            {{ subtext }}
          </span>
        </div>
      </div>

      <!-- Audio player (when there's a recording) -->
      <AudioChip
        v-if="recordingAttachment"
        :attachment="recordingAttachment"
        show-transcribed-text
      />

      <!-- Call back button (missed inbound) -->
      <button
        v-if="canCallBack"
        type="button"
        class="flex justify-center items-center gap-2 px-3 h-10 bg-n-teal-9 hover:bg-n-teal-10 rounded-full transition-colors"
        @click="handleCallBack"
      >
        <i class="text-base text-white i-ph-phone-bold" />
        <span class="text-sm font-medium text-white tracking-tight">
          {{ $t('CONVERSATION.VOICE_CALL.CALL_BACK') }}
        </span>
      </button>

      <!-- Join call button (ringing inbound) -->
      <button
        v-if="canJoinCall"
        type="button"
        class="flex justify-center items-center gap-2 px-3 h-10 bg-n-teal-9 hover:bg-n-teal-10 disabled:opacity-50 rounded-full transition-colors"
        :disabled="isJoining"
        @click="handleJoinCall"
      >
        <i class="text-base text-white i-ph-phone-bold" />
        <span class="text-sm font-medium text-white tracking-tight">
          {{ $t('CONVERSATION.VOICE_CALL.JOIN_CALL') }}
        </span>
      </button>
    </div>
  </BaseBubble>
</template>
