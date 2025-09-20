<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import VoiceAPI from 'dashboard/api/channels/voice';
import { useRingtone } from 'dashboard/composables/useRingtone';

const store = useStore();
const router = useRouter();
const route = useRoute();

const callDuration = ref(0);
const durationTimer = ref(null);
const { start: startRingTone, stop: stopRingTone } = useRingtone();

// Computed properties
const activeCall = computed(() => store.getters['calls/getActiveCall']);
const incomingCall = computed(() => store.getters['calls/getIncomingCall']);
const hasIncomingCall = computed(() => store.getters['calls/hasIncomingCall']);
const hasActiveCall = computed(() => store.getters['calls/hasActiveCall']);

const isIncoming = computed(() => {
  return hasIncomingCall.value && !hasActiveCall.value && !incomingCall.value?.isOutbound;
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
  return callInfo.value?.contactName || callInfo.value?.phoneNumber || 'Call in progress';
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

// Ringtone handled via useRingtone composable

const isJoining = ref(false);

const joinConference = async () => {
  const callData = callInfo.value;
  if (!callData) return;
  if (isJoined.value || isJoining.value) return;
  
  try {
    isJoining.value = true;
    // Initialize Twilio device
    await VoiceAPI.initializeDevice(callData.inboxId, { store });

    // Join the call on server and use returned conference_sid
    const joinRes = await VoiceAPI.joinConference({
      conversation_id: callData.conversationId,
      inbox_id: callData.inboxId,
      call_sid: callData.callSid,
    });

    const conferenceSid = joinRes.conference_sid;

    // Join client call using server-provided conference sid when available
    VoiceAPI.joinClientCall({ To: conferenceSid, conversationId: callData.conversationId });
    
    // Navigate to the conversation now that we're joining
    try {
      const path = `/app/accounts/${route.params.accountId}/conversations/${callData.conversationId}`;
      router.push({ path });
    } catch (_) {}

    // Promote to active and clear any incoming ringing state
    store.dispatch('calls/setActiveCall', {
      ...callData,
      isJoined: true,
      startedAt: Date.now(),
    });
    if (hasIncomingCall.value) {
      store.dispatch('calls/clearIncomingCall');
    }
    
    startDurationTimer();
    stopRingTone();
  } catch (error) {
    // Join call failed
  } finally {
    isJoining.value = false;
  }
};

const endCall = async () => {
  try {
    if (!callInfo.value) return;
    
    stopDurationTimer();
    callDuration.value = 0;
    stopRingTone();
    
    // End server call first to terminate on Twilio's side
    if (callInfo.value.inboxId && callInfo.value.conversationId) {
      try {
        await VoiceAPI.leaveConference(callInfo.value.inboxId, callInfo.value.conversationId);
      } catch (serverError) {
        // Server leave failed, continue client cleanup
      }
    }
    
    // Then end WebRTC connection
    VoiceAPI.endClientCall();
    
    // Clear call state - handle both active and outgoing calls
    if (hasActiveCall.value) {
      store.dispatch('calls/clearActiveCall');
    }
    if (hasIncomingCall.value) {
      store.dispatch('calls/clearIncomingCall');
    }
    
  } catch (error) {
    // End call failed, but still try to clean up
    VoiceAPI.endClientCall();
    if (hasActiveCall.value) {
      store.dispatch('calls/clearActiveCall');
    }
    if (hasIncomingCall.value) {
      store.dispatch('calls/clearIncomingCall');
    }
    stopRingTone();
  }
};

const acceptCall = async () => {
  await joinConference();
};

const rejectCall = async () => {
  if (!incomingCall.value) return;
  
  // End any WebRTC connection first
  VoiceAPI.endClientCall();
  // Clear state; server-side webhook will mark no-answer on conference end
  store.dispatch('calls/clearIncomingCall');
  stopRingTone();
};

// Watchers
watch([isOutgoing, incomingCall], ([newIsOutgoing, newIncomingCall]) => {
  // Auto-join outgoing calls when they appear
  if (newIsOutgoing && newIncomingCall?.isOutbound && !isJoined.value) {
    joinConference();
  }
}, { immediate: true });

// Watch for call ending from server side (when contact hangs up)
watch([hasActiveCall, hasIncomingCall], ([newHasActive, newHasIncoming]) => {
  // If both active and incoming calls are gone, stop timer and hide widget
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
    v-if="hasActiveCall || hasIncomingCall"
    class="fixed bottom-4 right-4 z-50 w-80 rounded-xl bg-white shadow-2xl border border-slate-200 dark:bg-slate-800 dark:border-slate-700"
  >
    <!-- Header -->
    <div class="flex items-center justify-between p-4 border-b border-slate-100 dark:border-slate-700">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
          <i class="i-ph-phone text-green-600 text-lg"></i>
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
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
          {{ $t('CONVERSATION.VOICE_CALL.INCOMING_CALL') }}
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET') }}
        </p>
      </div>
      
      <div v-else-if="isOutgoing">
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
          {{ $t('CONVERSATION.VOICE_CALL.OUTGOING_CALL') }}
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ $t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET') }}
        </p>
      </div>
      
      <div v-else-if="isJoined">
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
          {{ $t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS') }}
        </p>
        <p class="text-2xl font-mono text-green-600 dark:text-green-400">
          {{ formattedCallDuration }}
        </p>
      </div>
      
      <div v-else>
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100">
          {{ $t('CONVERSATION.VOICE_CALL.OUTGOING_CALL') }}
        </p>
      </div>
    </div>

    <!-- Incoming Call Actions -->
    <div v-if="isIncoming" class="p-4 flex space-x-3">
      <button
        @click="rejectCall"
        class="flex-1 flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-4 py-3 rounded-lg"
      >
        <i class="i-ph-phone-x text-lg"></i>
        <span>{{ $t('CONVERSATION.VOICE_CALL.REJECT_CALL') }}</span>
      </button>
      
      <button
        @click="acceptCall"
        class="flex-1 flex items-center justify-center space-x-2 bg-green-100 hover:bg-green-200 text-green-700 px-4 py-3 rounded-lg"
      >
        <i class="i-ph-phone text-lg"></i>
        <span>{{ $t('CONVERSATION.VOICE_CALL.JOIN_CALL') }}</span>
      </button>
    </div>

    <!-- Outgoing Call Actions -->
    <div v-else-if="isOutgoing" class="p-4 flex justify-center">
      <button
        @click="endCall"
        class="flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-6 py-3 rounded-lg"
      >
        <i class="i-ph-phone-x text-lg"></i>
        <span>{{ $t('CONVERSATION.VOICE_CALL.END_CALL') }}</span>
      </button>
    </div>

    <!-- Active Call Controls -->
    <div v-else-if="isJoined" class="p-4 flex justify-center">
      <button
        @click="endCall"
        class="flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-6 py-3 rounded-lg"
      >
        <i class="i-ph-phone-x text-lg"></i>
        <span>{{ $t('CONVERSATION.VOICE_CALL.END_CALL') }}</span>
      </button>
    </div>
  </div>
</template>
