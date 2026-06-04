<script setup>
import { watch, ref, computed, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useCallSession } from 'dashboard/composables/useCallSession';
import WindowVisibilityHelper from 'dashboard/helper/AudioAlerts/WindowVisibilityHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import InternalConversationsAPI from 'dashboard/api/internalConversations';
import { useCallsStore } from 'dashboard/stores/calls';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VoicePermissionsModal from 'dashboard/components/widgets/VoicePermissionsModal.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

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
  transferCall,
  sendDtmf,
} = useCallSession();

const callsStore = useCallsStore();
const showTransferModal = ref(false);
const transferQuery = ref('');
const selectedAgent = ref(null);
const isTransferring = ref(false);
const showKeypadModal = ref(false);
const keypadDisplay = ref('');
const showInternalCallModal = ref(false);
const isInternalCalling = ref(false);
const selectedInternalAgentId = ref('');
const selectedInternalVoiceInboxId = ref('');
const selectedInternalInboxId = ref('');
const showVoicePermissionModal = ref(false);
const pendingCallToJoin = ref(null);

const getCallInfo = call => {
  const conversation = store.getters.getConversationById(call?.conversationId);
  const inboxId = call?.inboxId || conversation?.inbox_id;
  const inbox = store.getters['inboxes/getInboxById'](inboxId);
  const sender = conversation?.meta?.sender;
  return {
    conversation,
    inbox,
    contactName: sender?.name || sender?.phone_number || 'Unknown caller',
    inboxName: inbox?.name || 'Customer support',
    avatar: sender?.avatar || sender?.thumbnail,
  };
};

const activeCallContext = computed(() => {
  const call = activeCall.value;
  if (!call) return null;
  const conversation = getCallInfo(call).conversation;
  const inboxId = call.inboxId || conversation?.inbox_id;
  return {
    call,
    conversationId: call.conversationId,
    inboxId,
  };
});

const canTransfer = computed(() => {
  const inboxId = activeCallContext.value?.inboxId;
  if (!inboxId) return false;
  const inbox = store.getters['inboxes/getInboxById'](inboxId);
  return inbox?.provider === 'custom';
});

const assignableAgents = computed(() => {
  const inboxId = activeCallContext.value?.inboxId;
  if (!inboxId) return [];
  return store.getters['inboxAssignableAgents/getAssignableAgents'](`${inboxId}`);
});

const inboxes = computed(() => store.getters['inboxes/getInboxes'] || []);
const internalInboxes = computed(() =>
  inboxes.value.filter(inbox => inbox.channel_type === INBOX_TYPES.INTERNAL)
);
const voiceInboxes = computed(() =>
  inboxes.value.filter(
    inbox => inbox.channel_type === INBOX_TYPES.VOICE && inbox.provider === 'custom'
  )
);
const allAgents = computed(() => store.getters['agents/getAgents'] || []);
const currentUserId = computed(() => store.getters.getCurrentUserID);
const internalCallAgents = computed(() =>
  (allAgents.value || []).filter(agent => agent.id !== currentUserId.value)
);
const canInternalCall = computed(
  () =>
    internalCallAgents.value.length > 0 &&
    voiceInboxes.value.length > 0 &&
    internalInboxes.value.length > 0
);

const ringAudio = ref(null);
const ringSource = ref('');
const ringTone = computed(() => {
  if (activeCall.value) {
    const conversation = getCallInfo(activeCall.value).conversation;
    const status = conversation?.additional_attributes?.call_status;
    if (status === 'ringing') {
      return activeCall.value.callDirection === 'outbound' ? 'outbound' : 'inbound';
    }
    return null;
  }

  for (const call of callsStore.calls) {
    const conversation = getCallInfo(call).conversation;
    const status = conversation?.additional_attributes?.call_status;
    if (status === 'ringing') {
      if (call.callDirection === 'outbound') return 'outbound';
      if (call.callDirection === 'inbound' && !hasActiveCall.value) return 'inbound';
    }
    if (!status && call.callDirection === 'inbound' && !hasActiveCall.value) {
      return 'inbound';
    }
  }
  return null;
});

const filteredAgents = computed(() => {
  const query = transferQuery.value.toLowerCase();
  const currentUserId = store.getters.getCurrentUserID;
  return assignableAgents.value.filter(agent => {
    if (agent.id === currentUserId) return false;
    if (!query) return true;
    return agent.name.toLowerCase().includes(query);
  });
});

const openTransferModal = async () => {
  if (!canTransfer.value) return;
  const inboxId = activeCallContext.value?.inboxId;
  if (!inboxId) return;
  await store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
  selectedAgent.value = null;
  transferQuery.value = '';
  showTransferModal.value = true;
};

const closeTransferModal = () => {
  showTransferModal.value = false;
  selectedAgent.value = null;
};

const keypadButtons = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['*', '0', '#'],
];
const keypadDigits = computed(() => keypadButtons.flat());

const openKeypadModal = () => {
  keypadDisplay.value = '';
  showKeypadModal.value = true;
};

const closeKeypadModal = () => {
  showKeypadModal.value = false;
};

const handleKeypadInput = digit => {
  const ctx = activeCallContext.value;
  if (!ctx?.inboxId || !digit) return;
  keypadDisplay.value += digit;
  sendDtmf({ inboxId: ctx.inboxId, digits: digit });
};

const clearKeypad = () => {
  keypadDisplay.value = '';
};

const setInternalCallDefaults = () => {
  if (internalCallAgents.value.length === 1) {
    selectedInternalAgentId.value = internalCallAgents.value[0].id;
  }
  if (voiceInboxes.value.length === 1) {
    selectedInternalVoiceInboxId.value = voiceInboxes.value[0].id;
  }
  if (internalInboxes.value.length === 1) {
    selectedInternalInboxId.value = internalInboxes.value[0].id;
  }
};

const openInternalCallModal = () => {
  if (!canInternalCall.value) return;
  selectedInternalAgentId.value = '';
  selectedInternalVoiceInboxId.value = '';
  selectedInternalInboxId.value = '';
  setInternalCallDefaults();
  showInternalCallModal.value = true;
};

const closeInternalCallModal = () => {
  showInternalCallModal.value = false;
};

const startInternalCall = async () => {
  const internalInboxId =
    selectedInternalInboxId.value ||
    (internalInboxes.value.length === 1 ? internalInboxes.value[0]?.id : null);
  const voiceInboxId =
    selectedInternalVoiceInboxId.value ||
    (voiceInboxes.value.length === 1 ? voiceInboxes.value[0]?.id : null);

  if (
    !selectedInternalAgentId.value ||
    !voiceInboxId ||
    !internalInboxId ||
    isInternalCalling.value
  ) {
    return;
  }

  isInternalCalling.value = true;
  try {
    const internalConversation = await InternalConversationsAPI.create({
      inbox_id: internalInboxId,
      participant_ids: [selectedInternalAgentId.value],
    });
    if (internalConversation?.data) {
      store.dispatch('addConversation', internalConversation.data);
    }

    const conversationId = internalConversation?.data?.id;
    const voiceResponse = await InternalConversationsAPI.initiateVoiceCall({
      conversationId,
      voiceInboxId,
      targetAgentId: selectedInternalAgentId.value,
    });

    const {
      call_sid: callSid,
      conversation_id: createdConversationId,
      inbox_id: voiceInboxId,
    } = voiceResponse?.data || {};

    if (callSid && createdConversationId) {
      callsStore.addCall({
        callSid,
        conversationId: createdConversationId,
        inboxId: voiceInboxId,
        callDirection: 'outbound',
      });
    }

    useAlert(t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_INITIATED'));
    closeInternalCallModal();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[VoiceWidget] internal call error', { error });
    useAlert(t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_FAILED'));
  } finally {
    isInternalCalling.value = false;
  }
};

const handleTransfer = async () => {
  const ctx = activeCallContext.value;
  if (!ctx?.inboxId || !selectedAgent.value?.id) return;

  isTransferring.value = true;
  try {
    await transferCall({
      conversationId: ctx.conversationId,
      inboxId: ctx.inboxId,
      targetAgentId: selectedAgent.value.id,
      callSid: ctx.call.callSid,
    });
    await store.dispatch('assignAgent', {
      conversationId: ctx.conversationId,
      agentId: selectedAgent.value.id,
    });
    useAlert(t('CONVERSATION.VOICE_WIDGET.TRANSFER_SUCCESS'));
    closeTransferModal();
  } catch (error) {
    useAlert(t('CONVERSATION.VOICE_WIDGET.TRANSFER_ERROR'));
  } finally {
    isTransferring.value = false;
  }
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

const hasMicrophonePermission = async () => {
  if (!navigator.permissions?.query) return false;

  try {
    const status = await navigator.permissions.query({ name: 'microphone' });
    return status.state === 'granted';
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn('[VoiceWidget] microphone permission check failed', { error });
    return false;
  }
};

const openVoicePermissionModal = call => {
  pendingCallToJoin.value = call;
  showVoicePermissionModal.value = true;
};

const closeVoicePermissionModal = () => {
  showVoicePermissionModal.value = false;
  pendingCallToJoin.value = null;
};

const confirmVoicePermissionModal = async () => {
  showVoicePermissionModal.value = false;
  const call = pendingCallToJoin.value;
  pendingCallToJoin.value = null;
  if (call) {
    await handleJoinCall(call);
  }
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
    inboxId: call.inboxId || conversation.inbox_id,
    callSid: call.callSid,
  });

  if (result) {
    router.push({
      name: 'inbox_conversation',
      params: { conversation_id: call.conversationId },
    });
  }
};

const requestJoinCall = async call => {
  if (!call || isJoining.value) return;
  const hasPermission = await hasMicrophonePermission();
  if (hasPermission) {
    await handleJoinCall(call);
    return;
  }
  openVoicePermissionModal(call);
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
      requestJoinCall(call);
    }
  },
  { immediate: true }
);

watch(
  ringTone,
  async tone => {
    if (!ringAudio.value) {
      ringAudio.value = new Audio();
      ringAudio.value.loop = true;
    }

    if (!tone) {
      ringAudio.value.pause();
      ringAudio.value.currentTime = 0;
      return;
    }

    const nextSource =
      tone === 'outbound'
        ? '/audio/dashboard/ringing.wav'
        : '/audio/dashboard/ringtone.wav';

    if (ringSource.value !== nextSource) {
      ringSource.value = nextSource;
      ringAudio.value.src = nextSource;
      ringAudio.value.load();
    }

    try {
      await ringAudio.value.play();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn('[VoiceWidget] ringtone blocked', { error });
    }
  },
  { immediate: true }
);

onUnmounted(() => {
  if (ringAudio.value) {
    ringAudio.value.pause();
    ringAudio.value.currentTime = 0;
  }
});
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
          @click="requestJoinCall(call)"
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
        <!-- <button
          v-if="hasActiveCall && canTransfer"
          class="flex justify-center items-center w-10 h-10 bg-n-slate-9 hover:bg-n-slate-10 rounded-full transition-colors"
          @click="openTransferModal"
        >
          <i class="text-lg text-white i-lucide-phone-forwarded" />
        </button> -->
        <button
          v-if="hasActiveCall"
          class="flex justify-center items-center w-10 h-10 bg-n-slate-9 hover:bg-n-slate-10 rounded-full transition-colors"
          :title="$t('CONVERSATION.VOICE_WIDGET.DIALPAD_TITLE')"
          @click="openKeypadModal"
        >
          <i class="text-lg text-white i-ph-keyboard-bold" />
        </button>
        <!-- <button
          v-if="hasActiveCall && canInternalCall"
          class="flex justify-center items-center w-10 h-10 bg-n-slate-9 hover:bg-n-slate-10 rounded-full transition-colors"
          :title="$t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_BUTTON')"
          @click="openInternalCallModal"
        >
          <i class="text-lg text-white i-ph-users-three-bold" />
        </button> -->
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
          @click="requestJoinCall(incomingCalls[0])"
        >
          <i class="text-lg text-white i-ph-phone-bold" />
        </button>
      </div>
    </div>

    <woot-modal v-model:show="showTransferModal" :on-close="closeTransferModal">
      <div class="flex flex-col gap-4 p-6 w-full max-w-md">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.TRANSFER_TITLE') }}
        </h3>
        <input
          v-model="transferQuery"
          type="search"
          class="w-full px-3 py-2 rounded-md border border-n-strong bg-transparent text-sm"
          :placeholder="$t('CONVERSATION.VOICE_WIDGET.TRANSFER_SEARCH_PLACEHOLDER')"
        />
        <div class="max-h-64 overflow-y-auto flex flex-col gap-2">
          <button
            v-for="agent in filteredAgents"
            :key="agent.id"
            class="flex items-center gap-2 px-3 py-2 rounded-md hover:bg-n-slate-3 text-left"
            @click="selectedAgent = agent"
          >
            <Avatar
              :name="agent.name"
              :src="agent.thumbnail"
              :size="28"
              rounded-full
            />
            <span class="text-sm text-n-slate-12">
              {{ agent.name }}
            </span>
          </button>
        </div>
        <div class="flex justify-end gap-2">
          <NextButton
            faded
            slate
            :label="$t('CONVERSATION.VOICE_WIDGET.TRANSFER_CANCEL')"
            @click="closeTransferModal"
          />
          <NextButton
            :label="$t('CONVERSATION.VOICE_WIDGET.TRANSFER_CONFIRM')"
            :disabled="!selectedAgent"
            :is-loading="isTransferring"
            @click="handleTransfer"
          />
        </div>
      </div>
    </woot-modal>

    <woot-modal v-model:show="showKeypadModal" :on-close="closeKeypadModal">
      <div class="flex flex-col gap-4 p-6 w-[14rem] max-w-full">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.DIALPAD_TITLE') }}
        </h3>
        <div class="text-center text-lg font-mono text-n-slate-12 min-h-[28px]">
          {{ keypadDisplay || ' ' }}
        </div>
        <div class="grid grid-cols-3 gap-3">
          <button
          v-for="digit in keypadDigits"
          :key="digit"
          class="h-12 rounded-lg bg-n-slate-3 text-n-slate-12 text-lg font-semibold hover:bg-n-slate-4 transition-colors"
          @click="handleKeypadInput(digit)"
        >
          {{ digit }}
          </button>
        </div>
        <div class="flex justify-end gap-2">
          <NextButton
            faded
            slate
            :label="$t('CONVERSATION.VOICE_WIDGET.DIALPAD_CLEAR')"
            @click="clearKeypad"
          />
          <NextButton
            :label="$t('CONVERSATION.VOICE_WIDGET.DIALPAD_CLOSE')"
            @click="closeKeypadModal"
          />
        </div>
      </div>
    </woot-modal>

    <woot-modal
      v-model:show="showInternalCallModal"
      :on-close="closeInternalCallModal"
    >
      <div class="flex flex-col gap-4 p-6 w-full max-w-md">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ $t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_TITLE') }}
        </h3>
        <label class="flex flex-col gap-2">
          <span class="text-sm text-n-slate-11">
            {{ $t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_PICK_AGENT') }}
          </span>
          <select
            v-model="selectedInternalAgentId"
            class="rounded-md border border-n-strong bg-transparent px-3 py-2 text-sm"
          >
            <option disabled value="">--</option>
            <option
              v-for="agent in internalCallAgents"
              :key="agent.id"
              :value="agent.id"
            >
              {{ agent.name }}
            </option>
          </select>
        </label>

        <label v-if="voiceInboxes.length > 1" class="flex flex-col gap-2">
          <span class="text-sm text-n-slate-11">
            {{ $t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_PICK_INBOX') }}
          </span>
          <select
            v-model="selectedInternalVoiceInboxId"
            class="rounded-md border border-n-strong bg-transparent px-3 py-2 text-sm"
          >
            <option disabled value="">--</option>
            <option
              v-for="inbox in voiceInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>
        </label>

        <label v-if="internalInboxes.length > 1" class="flex flex-col gap-2">
          <span class="text-sm text-n-slate-11">
            {{ $t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_PICK_INTERNAL_INBOX') }}
          </span>
          <select
            v-model="selectedInternalInboxId"
            class="rounded-md border border-n-strong bg-transparent px-3 py-2 text-sm"
          >
            <option disabled value="">--</option>
            <option
              v-for="inbox in internalInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>
        </label>

        <div class="flex justify-end gap-2">
          <NextButton
            faded
            slate
            :label="$t('CONVERSATION.VOICE_WIDGET.TRANSFER_CANCEL')"
            @click="closeInternalCallModal"
          />
          <NextButton
            :label="$t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_START')"
            :disabled="!selectedInternalAgentId || !selectedInternalVoiceInboxId"
            :is-loading="isInternalCalling"
            @click="startInternalCall"
          />
        </div>
      </div>
    </woot-modal>
  </div>

  <VoicePermissionsModal
    :show="showVoicePermissionModal"
    @close="closeVoicePermissionModal"
    @confirm="confirmVoicePermissionModal"
  />
</template>
