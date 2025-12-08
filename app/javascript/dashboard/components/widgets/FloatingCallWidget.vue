<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useRingtone } from 'dashboard/composables/useRingtone';
import { useCallSession } from 'dashboard/composables/useCallSession';

const router = useRouter();
const route = useRoute();

const callDuration = ref(0);
const durationTimer = ref(null);
const { start: startRingTone, stop: stopRingTone } = useRingtone();

// Global call session state/actions
const {
  activeCall,
  incomingCall,
  hasActiveCall,
  hasIncomingCall,
  isJoining,
  joinCall,
  endCall: endCallSession,
  rejectIncomingCall,
} = useCallSession();

const isIncoming = computed(() => {
  return (
    hasIncomingCall.value &&
    !hasActiveCall.value &&
    !incomingCall.value?.isOutbound
  );
});
const isJoined = computed(() => activeCall.value && activeCall.value.isJoined);
const isOutgoing = computed(() => {
  return (
    (hasIncomingCall.value && incomingCall.value?.isOutbound) ||
    (hasActiveCall.value && !isJoined.value)
  );
});
const callInfo = computed(() =>
  isIncoming.value ? incomingCall.value : activeCall.value || incomingCall.value
);

const formattedCallDuration = computed(() => {
  const minutes = Math.floor(callDuration.value / 60);
  const seconds = callDuration.value % 60;
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
});

const contactDisplayName = computed(() => {
  return (
    callInfo.value?.contactName ||
    callInfo.value?.phoneNumber ||
    'Call in progress'
  );
});

const inboxDisplayName = computed(() => {
  return callInfo.value?.inboxName || 'Customer support';
});

// Methods
const startDurationTimer = () => {
  if (durationTimer.value) clearInterval(durationTimer.value);
  durationTimer.value = setInterval(() => {
    callDuration.value += 1;
  }, 1000);
};

const stopDurationTimer = () => {
  if (durationTimer.value) {
    clearInterval(durationTimer.value);
    durationTimer.value = null;
  }
};

const joinConference = async () => {
  const callData = callInfo.value;
  if (isJoined.value || isJoining.value) return;

  const result = await joinCall({
    conversationId: callData.conversationId,
    inboxId: callData.inboxId,
    callSid: callData.callSid,
    callMeta: callData,
  });

  if (result) {
    const path = `/app/accounts/${route.params.accountId}/conversations/${callData.conversationId}`;
    router.push({ path });
    startDurationTimer();
    stopRingTone();
  }
};

const endCall = async () => {
  const callData = callInfo.value;
  if (!callData) return;

  stopDurationTimer();
  callDuration.value = 0;
  stopRingTone();
  await endCallSession({
    conversationId: callData.conversationId,
    inboxId: callData.inboxId,
  });
};

const acceptCall = async () => {
  await joinConference();
};

const rejectCall = async () => {
  if (!incomingCall.value) return;

  rejectIncomingCall();
  stopRingTone();
};

// Watchers
watch(
  [isOutgoing, incomingCall],
  ([newIsOutgoing, newIncomingCall]) => {
    // Auto-join outgoing calls when they appear
    if (newIsOutgoing && newIncomingCall?.isOutbound && !isJoined.value) {
      joinConference();
    }
  },
  { immediate: true }
);

watch([hasActiveCall, hasIncomingCall], ([newHasActive, newHasIncoming]) => {
  if (!newHasActive && !newHasIncoming) {
    stopDurationTimer();
    callDuration.value = 0;
    stopRingTone();
  }
});

// Start/stop ringtone when incoming state toggles
watch(
  isIncoming,
  newVal => {
    if (newVal) {
      startRingTone();
    } else {
      stopRingTone();
    }
  },
  { immediate: true }
);

// Lifecycle
onMounted(() => {
  if (isJoined.value) {
    startDurationTimer();
  }
});

onBeforeUnmount(() => {
  stopDurationTimer();
  stopRingTone();
});
</script>

<template>
  <div
    v-show="hasActiveCall || hasIncomingCall"
    class="fixed bottom-4 right-4 z-50 w-80 rounded-xl bg-white shadow-2xl border border-slate-200 dark:bg-slate-800 dark:border-slate-700"
  >
    <!-- Header -->
    <div
      class="flex items-center justify-between p-4 border-b border-slate-100 dark:border-slate-700"
    >
      <div class="flex items-center space-x-3">
        <div
          class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center"
        >
          <i class="i-ph-phone text-green-600 text-lg" />
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
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1"
        >
          {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL') }}
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('CONVERSATION.VOICE_WIDGET.NOT_ANSWERED_YET') }}
        </p>
      </div>

      <div v-else-if="isOutgoing">
        <p
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1"
        >
          {{ $t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL') }}
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('CONVERSATION.VOICE_WIDGET.NOT_ANSWERED_YET') }}
        </p>
      </div>

      <div v-else-if="isJoined">
        <p
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1"
        >
          {{ $t('CONVERSATION.VOICE_WIDGET.CALL_IN_PROGRESS') }}
        </p>
        <p class="text-2xl font-mono text-green-600 dark:text-green-400">
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
    <div v-if="isIncoming" class="p-4 flex space-x-3">
      <button
        class="flex-1 flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-4 py-3 rounded-lg"
        @click="rejectCall"
      >
        <i class="i-ph-phone-x text-lg" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.REJECT_CALL') }}</span>
      </button>

      <button
        class="flex-1 flex items-center justify-center space-x-2 bg-green-100 hover:bg-green-200 text-green-700 px-4 py-3 rounded-lg"
        @click="acceptCall"
      >
        <i class="i-ph-phone text-lg" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.JOIN_CALL') }}</span>
      </button>
    </div>

    <!-- Outgoing Call Actions -->
    <div v-else-if="isOutgoing" class="p-4 flex justify-center">
      <button
        class="flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-6 py-3 rounded-lg"
        @click="endCall"
      >
        <i class="i-ph-phone-x text-lg" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.END_CALL') }}</span>
      </button>
    </div>

    <!-- Active Call Controls -->
    <div v-else-if="isJoined" class="p-4 flex justify-center">
      <button
        class="flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-6 py-3 rounded-lg"
        @click="endCall"
      >
        <i class="i-ph-phone-x text-lg" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.END_CALL') }}</span>
      </button>
    </div>
  </div>
</template>
