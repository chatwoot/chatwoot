<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useRingtone } from 'dashboard/composables/useRingtone';
import { useCallSession } from 'dashboard/composables/useCallSession';
import Button from 'dashboard/components-next/button/Button.vue';

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
    class="fixed ltr:right-4 rtl:left-4 bottom-4 z-50 w-80 bg-n-solid-2 rounded-xl shadow-2xl outline outline-1 outline-n-strong"
  >
    <!-- Header -->
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

      <!-- Minimization removed for MVP to reduce code -->
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
    <div v-else-if="isOutgoing || isJoined" class="flex justify-center p-4">
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
