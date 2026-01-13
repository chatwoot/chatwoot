<script setup>
import { watch } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useCallSession } from 'dashboard/composables/useCallSession';
import WindowVisibilityHelper from 'dashboard/helper/AudioAlerts/WindowVisibilityHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const router = useRouter();
const store = useStore();

const {
  activeCall,
  incomingCalls,
  hasActiveCall,
  isJoining,
  joinCall,
  endCall: endCallSession,
  rejectIncomingCall,
  dismissCall,
  formattedCallDuration,
} = useCallSession();

const getCallInfo = call => {
  const conversation = store.getters.getConversationById(call?.conversationId);
  const inbox = store.getters['inboxes/getInbox'](conversation?.inbox_id);
  const sender = conversation?.meta?.sender;
  return {
    conversation,
    inbox,
    contactName: sender?.name || sender?.phone_number || 'Unknown caller',
    inboxName: inbox?.name || 'Customer support',
    avatar: sender?.avatar || sender?.thumbnail,
  };
};

const handleEndCall = async () => {
  const call = activeCall.value;
  if (!call) return;

  const inboxId = call.inboxId || getCallInfo(call).conversation?.inbox_id;
  if (!inboxId) return;

  await endCallSession({
    conversationId: call.conversationId,
    inboxId,
  });
};

const handleJoinCall = async call => {
  const { conversation } = getCallInfo(call);
  if (!call || !conversation || isJoining.value) return;

  // End current active call before joining new one
  if (hasActiveCall.value) {
    await handleEndCall();
  }

  const result = await joinCall({
    conversationId: call.conversationId,
    inboxId: conversation.inbox_id,
    callSid: call.callSid,
  });

  if (result) {
    router.push({
      name: 'inbox_conversation',
      params: { conversation_id: call.conversationId },
    });
  }
};

// Auto-join outbound calls when window is visible
watch(
  () => incomingCalls.value[0],
  call => {
    if (
      call?.callDirection === 'outbound' &&
      !hasActiveCall.value &&
      WindowVisibilityHelper.isWindowVisible()
    ) {
      handleJoinCall(call);
    }
  },
  { immediate: true }
);
</script>

<template>
  <div
    v-if="incomingCalls.length || hasActiveCall"
    class="fixed ltr:right-4 rtl:left-4 bottom-4 z-50 flex flex-col gap-2 w-72"
  >
    <!-- Incoming Calls (shown above active call) -->
    <div
      v-for="call in hasActiveCall ? incomingCalls : []"
      :key="call.callSid"
      class="flex items-center gap-3 p-4 bg-n-solid-2 rounded-xl shadow-xl outline outline-1 outline-n-strong"
    >
      <div class="animate-pulse ring-2 ring-n-teal-9 rounded-full inline-flex">
        <Avatar
          :src="getCallInfo(call).avatar"
          :name="getCallInfo(call).contactName"
          :size="40"
          rounded-full
        />
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-n-slate-12 truncate mb-0">
          {{ getCallInfo(call).contactName }}
        </p>
        <p class="text-xs text-n-slate-11 truncate">
          {{ getCallInfo(call).inboxName }}
        </p>
      </div>
      <div class="flex shrink-0 gap-2">
        <button
          class="flex justify-center items-center w-10 h-10 bg-n-ruby-9 hover:bg-n-ruby-10 rounded-full transition-colors"
          @click="dismissCall(call.callSid)"
        >
          <i class="text-lg text-white i-ph-phone-x-bold" />
        </button>
        <button
          class="flex justify-center items-center w-10 h-10 bg-n-teal-9 hover:bg-n-teal-10 rounded-full transition-colors"
          @click="handleJoinCall(call)"
        >
          <i class="text-lg text-white i-ph-phone-bold" />
        </button>
      </div>
    </div>

    <!-- Main Call Widget -->
    <div
      v-if="hasActiveCall || incomingCalls.length"
      class="flex items-center gap-3 p-4 bg-n-solid-2 rounded-xl shadow-xl outline outline-1 outline-n-strong"
    >
      <div
        class="ring-2 ring-n-teal-9 rounded-full inline-flex"
        :class="{ 'animate-pulse': !hasActiveCall }"
      >
        <Avatar
          :src="getCallInfo(activeCall || incomingCalls[0]).avatar"
          :name="getCallInfo(activeCall || incomingCalls[0]).contactName"
          :size="40"
          rounded-full
        />
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-n-slate-12 truncate mb-0">
          {{ getCallInfo(activeCall || incomingCalls[0]).contactName }}
        </p>
        <p v-if="hasActiveCall" class="font-mono text-sm text-n-teal-9">
          {{ formattedCallDuration }}
        </p>
        <p v-else class="text-xs text-n-slate-11">
          {{
            incomingCalls[0]?.callDirection === 'outbound'
              ? $t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL')
              : $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL')
          }}
        </p>
      </div>
      <div class="flex shrink-0 gap-2">
        <button
          class="flex justify-center items-center w-10 h-10 bg-n-ruby-9 hover:bg-n-ruby-10 rounded-full transition-colors"
          @click="
            hasActiveCall
              ? handleEndCall()
              : rejectIncomingCall(incomingCalls[0]?.callSid)
          "
        >
          <i class="text-lg text-white i-ph-phone-x-bold" />
        </button>
        <button
          v-if="!hasActiveCall"
          class="flex justify-center items-center w-10 h-10 bg-n-teal-9 hover:bg-n-teal-10 rounded-full transition-colors"
          @click="handleJoinCall(incomingCalls[0])"
        >
          <i class="text-lg text-white i-ph-phone-bold" />
        </button>
      </div>
    </div>
  </div>
</template>
