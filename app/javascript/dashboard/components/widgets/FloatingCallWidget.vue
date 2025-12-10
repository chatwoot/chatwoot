<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useRingtone } from 'dashboard/composables/useRingtone';
import { useCallSession } from 'dashboard/composables/useCallSession';

const router = useRouter();
const route = useRoute();
const { start: startRingTone, stop: stopRingTone } = useRingtone();

const {
  callState,
  CALL_STATES,
  currentCall,
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

const contactDisplayName = computed(() => {
  return (
    currentCall.value?.contactName ||
    currentCall.value?.phoneNumber ||
    'Call in progress'
  );
});

const inboxDisplayName = computed(() => {
  return currentCall.value?.inboxName || 'Customer support';
});

const joinConference = async () => {
  const callData = currentCall.value;
  if (!callData || isJoined.value || isJoining.value) return;

  const result = await joinCall({
    conversationId: callData.conversationId,
    inboxId: callData.inboxId,
    callSid: callData.callSid,
    callMeta: callData,
  });

  if (result) {
    const path = `/app/accounts/${route.params.accountId}/conversations/${callData.conversationId}`;
    router.push({ path });
    stopRingTone();
  }
};

const endCall = async () => {
  const callData = currentCall.value;
  if (!callData) return;

  stopRingTone();
  await endCallSession({
    conversationId: callData.conversationId,
    inboxId: callData.inboxId,
  });
};

const acceptCall = async () => {
  await joinConference();
};

const rejectCall = () => {
  rejectIncomingCall();
  stopRingTone();
};

// Auto-join outgoing calls
watch(
  () => [callState.value, currentCall.value?.isOutbound],
  ([state, isOutbound]) => {
    if (state === CALL_STATES.OUTGOING && isOutbound && !isJoined.value) {
      joinConference();
    }
  },
  { immediate: true }
);

// Manage ringtone based on call state
watch(
  callState,
  state => {
    if (state === CALL_STATES.INCOMING) {
      startRingTone();
    } else {
      stopRingTone();
    }
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  stopRingTone();
});
</script>

<template>
  <div
    v-show="showWidget"
    class="fixed right-4 bottom-4 z-50 w-80 bg-white rounded-xl border shadow-2xl border-slate-200 dark:bg-slate-800 dark:border-slate-700"
  >
    <!-- Header -->
    <div
      class="flex justify-between items-center p-4 border-b border-slate-100 dark:border-slate-700"
    >
      <div class="flex items-center space-x-3">
        <div
          class="flex justify-center items-center w-10 h-10 bg-green-100 rounded-full"
        >
          <i class="text-lg text-green-600 i-ph-phone" />
        </div>
        <div>
          <h3 class="text-sm font-medium text-slate-900 dark:text-slate-100">
            {{ inboxDisplayName }}
          </h3>
          <p class="text-xs text-slate-500 dark:text-slate-400">
            {{ contactDisplayName }}
          </p>
        </div>
      </div>

      <!-- Minimization removed for MVP to reduce code -->
    </div>

    <!-- Call Status -->
    <div class="p-4 text-center">
      <div v-if="isIncoming">
        <p
          class="mb-1 text-lg font-semibold text-slate-900 dark:text-slate-100"
        >
          {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL') }}
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('CONVERSATION.VOICE_WIDGET.NOT_ANSWERED_YET') }}
        </p>
      </div>

      <div v-else-if="isOutgoing">
        <p
          class="mb-1 text-lg font-semibold text-slate-900 dark:text-slate-100"
        >
          {{ $t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL') }}
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('CONVERSATION.VOICE_WIDGET.NOT_ANSWERED_YET') }}
        </p>
      </div>

      <div v-else-if="isJoined">
        <p
          class="mb-1 text-lg font-semibold text-slate-900 dark:text-slate-100"
        >
          {{ $t('CONVERSATION.VOICE_WIDGET.CALL_IN_PROGRESS') }}
        </p>
        <p class="font-mono text-2xl text-green-600 dark:text-green-400">
          {{ formattedCallDuration }}
        </p>
      </div>

      <div v-else>
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100">
          {{ $t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL') }}
        </p>
      </div>
    </div>

    <!-- Incoming Call Actions -->
    <div v-if="isIncoming" class="flex p-4 space-x-3">
      <button
        class="flex flex-1 justify-center items-center px-4 py-3 space-x-2 text-red-700 bg-red-100 rounded-lg hover:bg-red-200"
        @click="rejectCall"
      >
        <i class="text-lg i-ph-phone-x" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.REJECT_CALL') }}</span>
      </button>

      <button
        class="flex flex-1 justify-center items-center px-4 py-3 space-x-2 text-green-700 bg-green-100 rounded-lg hover:bg-green-200"
        @click="acceptCall"
      >
        <i class="text-lg i-ph-phone" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.JOIN_CALL') }}</span>
      </button>
    </div>

    <!-- Outgoing Call Actions -->
    <div v-else-if="isOutgoing" class="flex justify-center p-4">
      <button
        class="flex justify-center items-center px-6 py-3 space-x-2 text-red-700 bg-red-100 rounded-lg hover:bg-red-200"
        @click="endCall"
      >
        <i class="text-lg i-ph-phone-x" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.END_CALL') }}</span>
      </button>
    </div>

    <!-- Active Call Controls -->
    <div v-else-if="isJoined" class="flex justify-center p-4">
      <button
        class="flex justify-center items-center px-6 py-3 space-x-2 text-red-700 bg-red-100 rounded-lg hover:bg-red-200"
        @click="endCall"
      >
        <i class="text-lg i-ph-phone-x" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.END_CALL') }}</span>
      </button>
    </div>
  </div>
</template>
