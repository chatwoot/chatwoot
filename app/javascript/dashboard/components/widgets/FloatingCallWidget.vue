<script setup>
import { computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useCallSession } from 'dashboard/composables/useCallSession';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import WindowVisibilityHelper from 'dashboard/helper/AudioAlerts/WindowVisibilityHelper';
import Button from 'dashboard/components-next/button/Button.vue';

const router = useRouter();
const store = useStore();

const {
  callState,
  CALL_STATES,
  currentCall,
  isOutbound,
  isJoining,
  joinCall,
  endCall: endCallSession,
  rejectIncomingCall,
  formattedCallDuration,
} = useCallSession();

const isIncoming = computed(() => callState.value === CALL_STATES.INCOMING);
const isOutgoing = computed(() => callState.value === CALL_STATES.OUTGOING);
const isJoined = computed(() => callState.value === CALL_STATES.JOINED);
const showWidget = computed(() => callState.value !== CALL_STATES.IDLE);

const currentUserId = computed(() => store.getters.getCurrentUserID);
const isInitiatedByMe = computed(
  () => currentCall.value?.senderId === currentUserId.value
);
const isHandledInAnotherTab = computed(
  () =>
    isOutgoing.value && isOutbound.value && !TwilioVoiceClient.hasActiveConnection
);

const conversation = computed(() => {
  const conversationId = currentCall.value?.conversationId;
  if (!conversationId) return null;
  return store.getters.getConversationById(conversationId);
});

const inbox = computed(() => {
  const inboxId = conversation.value?.inbox_id;
  if (!inboxId) return null;
  return store.getters['inboxes/getInbox'](inboxId);
});

const contactDisplayName = computed(() => {
  const sender = conversation.value?.meta?.sender;
  return sender?.name || sender?.phone_number || 'Unknown caller';
});

const inboxDisplayName = computed(() => {
  return inbox.value?.name || 'Customer support';
});

const joinConference = async () => {
  const callData = currentCall.value;
  const conv = conversation.value;
  if (!callData || !conv || isJoined.value || isJoining.value) return;

  const result = await joinCall({
    conversationId: callData.conversationId,
    inboxId: conv.inbox_id,
    callSid: callData.callSid,
  });

  if (result) {
    router.push({
      name: 'inbox_conversation',
      params: { conversation_id: callData.conversationId },
    });
  }
};

const endCall = async () => {
  const callData = currentCall.value;
  const conv = conversation.value;
  if (!callData || !conv) return;

  await endCallSession({
    conversationId: callData.conversationId,
    inboxId: conv.inbox_id,
  });
};

const acceptCall = async () => {
  await joinConference();
};

const rejectCall = () => {
  rejectIncomingCall();
};

// Auto-join outgoing calls only if initiated by me and window is visible
watch(
  () => [callState.value, isOutbound.value, isInitiatedByMe.value],
  ([state, outbound, initiatedByMe]) => {
    const shouldAutoJoin =
      state === CALL_STATES.OUTGOING &&
      outbound &&
      initiatedByMe &&
      WindowVisibilityHelper.isWindowVisible();
    if (shouldAutoJoin) {
      joinConference();
    }
  },
  { immediate: true }
);
</script>

<template>
  <div
    v-show="showWidget"
    class="fixed ltr:right-4 rtl:left-4 bottom-4 z-50 w-80 bg-n-solid-2 rounded-xl shadow-2xl outline outline-1 outline-n-strong"
  >
    <div class="flex justify-between items-center p-4 border-b border-n-strong">
      <div class="flex items-center space-x-3">
        <div
          class="flex justify-center items-center w-10 h-10 bg-n-teal-3 rounded-full"
        >
          <i class="text-lg text-n-teal-9 i-ph-phone" />
        </div>
        <div>
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ inboxDisplayName }}
          </h3>
          <p class="text-xs text-n-slate-11">
            {{ contactDisplayName }}
          </p>
        </div>
      </div>
    </div>

    <!-- Call Status -->
    <div class="p-4 text-center">
      <div v-if="isIncoming">
        <p class="mb-1 text-lg font-semibold text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL') }}
        </p>
        <p class="text-sm text-n-slate-11">
          {{ $t('CONVERSATION.VOICE_WIDGET.NOT_ANSWERED_YET') }}
        </p>
      </div>

      <div v-else-if="isHandledInAnotherTab">
        <p class="mb-1 text-lg font-semibold text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.CALL_IN_PROGRESS') }}
        </p>
        <p class="text-sm text-n-slate-11">
          {{ $t('CONVERSATION.VOICE_WIDGET.HANDLED_IN_ANOTHER_TAB') }}
        </p>
      </div>

      <div v-else-if="isOutgoing">
        <p class="mb-1 text-lg font-semibold text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL') }}
        </p>
        <p class="text-sm text-n-slate-11">
          {{ $t('CONVERSATION.VOICE_WIDGET.NOT_ANSWERED_YET') }}
        </p>
      </div>

      <div v-else-if="isJoined">
        <p class="mb-1 text-lg font-semibold text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.CALL_IN_PROGRESS') }}
        </p>
        <p class="font-mono text-2xl text-n-teal-9">
          {{ formattedCallDuration }}
        </p>
      </div>

      <div v-else>
        <p class="text-lg font-semibold text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL') }}
        </p>
      </div>
    </div>

    <!-- Incoming Call Actions -->
    <div v-if="isIncoming" class="flex gap-3 p-4">
      <Button
        faded
        ruby
        class="flex-1"
        icon="i-ph-phone-x"
        :label="$t('CONVERSATION.VOICE_WIDGET.REJECT_CALL')"
        @click="rejectCall"
      />
      <Button
        faded
        teal
        class="flex-1"
        icon="i-ph-phone"
        :label="$t('CONVERSATION.VOICE_WIDGET.JOIN_CALL')"
        @click="acceptCall"
      />
    </div>

    <!-- Outgoing or Active Call Actions -->
    <div
      v-else-if="(isOutgoing || isJoined) && !isHandledInAnotherTab"
      class="flex justify-center p-4"
    >
      <Button
        faded
        ruby
        icon="i-ph-phone-x"
        :label="$t('CONVERSATION.VOICE_WIDGET.END_CALL')"
        @click="endCall"
      />
    </div>
  </div>
</template>
