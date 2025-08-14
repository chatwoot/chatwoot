<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import VoiceAPI from 'dashboard/api/channels/voice';

const store = useStore();
const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const callDuration = ref(0);
const durationTimer = ref(null);

// Computed properties
const activeCall = computed(() => store.getters['calls/getActiveCall']);
const incomingCall = computed(() => store.getters['calls/getIncomingCall']);
const hasIncomingCall = computed(() => store.getters['calls/hasIncomingCall']);
const hasActiveCall = computed(() => store.getters['calls/hasActiveCall']);

const isIncoming = computed(() => {
  return hasIncomingCall.value && !hasActiveCall.value && !incomingCall.value?.isOutbound;
});
const isOutgoing = computed(() => {
  return (hasIncomingCall.value && incomingCall.value?.isOutbound) || (hasActiveCall.value && !isJoined.value);
});
const callInfo = computed(() => isIncoming.value ? incomingCall.value : activeCall.value || incomingCall.value);
const isJoined = computed(() => activeCall.value && activeCall.value.isJoined);

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

const joinCall = async () => {
  const callData = callInfo.value;
  if (!callData) return;
  
  try {
    // Initialize Twilio device
    await VoiceAPI.initializeDevice(callData.inboxId);
    
    // Join the call
    await VoiceAPI.joinCall({
      conversation_id: callData.conversationId,
      call_sid: callData.callSid,
      account_id: store.getters.getCurrentAccountId,
    });
    
    // Join client call
    const conferenceParams = {
      To: `conf_account_${store.getters.getCurrentAccountId}_conv_${callData.conversationId}`,
      account_id: store.getters.getCurrentAccountId,
    };
    
    VoiceAPI.joinClientCall(conferenceParams);
    
    // Move from incoming to active call for outbound calls
    if (incomingCall.value?.isOutbound) {
      store.dispatch('calls/clearIncomingCall');
      store.dispatch('calls/setActiveCall', {
        ...callData,
        isJoined: true,
        startedAt: Date.now(),
      });
    } else {
      // Mark as joined for regular active calls
      store.dispatch('calls/setActiveCall', {
        ...callData,
        isJoined: true,
        startedAt: Date.now(),
      });
    }
    
    startDurationTimer();
  } catch (error) {
    // Join call failed
  }
};

const endCall = async () => {
  try {
    if (!callInfo.value) return;
    
    stopDurationTimer();
    callDuration.value = 0;
    
    // End server call first to terminate on Twilio's side
    if (callInfo.value.callSid && callInfo.value.callSid !== 'pending' && callInfo.value.conversationId) {
      try {
        await VoiceAPI.endCall(callInfo.value.callSid, callInfo.value.conversationId);
      } catch (serverError) {
        // Server call end failed, but continue with client cleanup
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
    
    // Hide widget
    if (window.app && window.app.$data) {
      window.app.$data.showCallWidget = false;
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
    if (window.app && window.app.$data) {
      window.app.$data.showCallWidget = false;
    }
  }
};

const acceptCall = async () => {
  if (!incomingCall.value) return;
  
  try {
    // Initialize Twilio device
    const device = await VoiceAPI.initializeDevice(incomingCall.value.inboxId);
    
    // Join the call
    await VoiceAPI.joinCall({
      conversation_id: incomingCall.value.conversationId,
      call_sid: incomingCall.value.callSid,
      account_id: store.getters.getCurrentAccountId,
    });
    
    // Join client call
    const conferenceParams = {
      To: `conf_account_${store.getters.getCurrentAccountId}_conv_${incomingCall.value.conversationId}`,
      account_id: store.getters.getCurrentAccountId,
    };
    
    VoiceAPI.joinClientCall(conferenceParams);
    
    // Move to active call
    store.dispatch('calls/acceptIncomingCall');
    startDurationTimer();
  } catch (error) {
    // Accept call failed
  }
};

const rejectCall = async () => {
  if (!incomingCall.value) return;
  
  try {
    // End any WebRTC connection first to disconnect customer immediately
    VoiceAPI.endClientCall();
    
    // Then call server API to reject the call
    await VoiceAPI.rejectCall(incomingCall.value.callSid, incomingCall.value.conversationId);
    
    // Clear state
    store.dispatch('calls/clearIncomingCall');
    
    // Hide widget
    if (window.app && window.app.$data) {
      window.app.$data.showCallWidget = false;
    }
  } catch (error) {
    // Even if reject API fails, still clean up WebRTC and state
    VoiceAPI.endClientCall();
    store.dispatch('calls/clearIncomingCall');
    if (window.app && window.app.$data) {
      window.app.$data.showCallWidget = false;
    }
  }
};

const minimizeWidget = () => {
  if (window.app && window.app.$data) {
    window.app.$data.showCallWidget = false;
  }
};

// Watchers
watch([isOutgoing, incomingCall], ([newIsOutgoing, newIncomingCall]) => {
  // Auto-join outgoing calls when they appear
  if (newIsOutgoing && newIncomingCall?.isOutbound && !isJoined.value) {
    joinCall();
  }
}, { immediate: true });

// Watch for call ending from server side (when contact hangs up)
watch([hasActiveCall, hasIncomingCall], ([newHasActive, newHasIncoming]) => {
  // If both active and incoming calls are gone, stop timer and hide widget
  if (!newHasActive && !newHasIncoming) {
    stopDurationTimer();
    callDuration.value = 0;
    if (window.app && window.app.$data) {
      window.app.$data.showCallWidget = false;
    }
  }
});

// Lifecycle
onMounted(() => {
  if (isJoined.value) {
    startDurationTimer();
  }
});

onBeforeUnmount(() => {
  stopDurationTimer();
});
</script>

<template>
  <div
    v-if="hasIncomingCall || hasActiveCall"
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
      
      <button
        @click="minimizeWidget"
        class="w-6 h-6 flex items-center justify-center rounded text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-700"
      >
        <i class="i-ph-minus text-sm"></i>
      </button>
    </div>

    <!-- Call Status -->
    <div class="p-4 text-center">
      <div v-if="isIncoming">
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
          Incoming Call
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          Please answer or decline
        </p>
      </div>
      
      <div v-else-if="isOutgoing">
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
          Outgoing Call
        </p>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          Connecting...
        </p>
      </div>
      
      <div v-else-if="isJoined">
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
          Call in Progress
        </p>
        <p class="text-2xl font-mono text-green-600 dark:text-green-400">
          {{ formattedCallDuration }}
        </p>
      </div>
      
      <div v-else>
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Connecting...
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
        <span>Decline</span>
      </button>
      
      <button
        @click="acceptCall"
        class="flex-1 flex items-center justify-center space-x-2 bg-green-100 hover:bg-green-200 text-green-700 px-4 py-3 rounded-lg"
      >
        <i class="i-ph-phone text-lg"></i>
        <span>Accept</span>
      </button>
    </div>

    <!-- Outgoing Call Actions -->
    <div v-else-if="isOutgoing" class="p-4 flex justify-center">
      <button
        @click="endCall"
        class="flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-6 py-3 rounded-lg"
      >
        <i class="i-ph-phone-x text-lg"></i>
        <span>Cancel</span>
      </button>
    </div>

    <!-- Active Call Controls -->
    <div v-else-if="isJoined" class="p-4 flex justify-center">
      <button
        @click="endCall"
        class="flex items-center justify-center space-x-2 bg-red-100 hover:bg-red-200 text-red-700 px-6 py-3 rounded-lg"
      >
        <i class="i-ph-phone-x text-lg"></i>
        <span>End Call</span>
      </button>
    </div>
  </div>
</template>