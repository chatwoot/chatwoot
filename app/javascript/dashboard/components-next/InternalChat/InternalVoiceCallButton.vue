<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import InternalConversationsAPI from 'dashboard/api/internalConversations';
import { useCallsStore } from 'dashboard/stores/calls';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  conversation: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const store = useStore();
const callsStore = useCallsStore();

const dialogRef = ref(null);
const isCalling = ref(false);
const selectedAgentId = ref('');
const selectedInboxId = ref('');

const inboxesList = useMapGetter('inboxes/getInboxes');
const agentsList = useMapGetter('agents/getAgents');

const voiceInboxes = computed(() =>
  (inboxesList.value || []).filter(
    inbox =>
      inbox.channel_type === INBOX_TYPES.VOICE && inbox.provider === 'custom'
  )
);

const participantIds = computed(() => {
  const attrs = props.conversation?.additional_attributes || {};
  const meta = props.conversation?.meta || {};
  return (attrs.participants || meta.participants || [])
    .map(id => Number(id))
    .filter(Boolean);
});

const currentUserId = computed(() => store.getters.getCurrentUserID);

const targetAgents = computed(() => {
  const ids = new Set(participantIds.value || []);
  return (agentsList.value || []).filter(
    agent => ids.has(agent.id) && agent.id !== currentUserId.value
  );
});

const shouldRender = computed(
  () => voiceInboxes.value.length > 0 && targetAgents.value.length > 0
);

const shouldPrompt = computed(
  () => voiceInboxes.value.length > 1 || targetAgents.value.length > 1
);

const setDefaults = () => {
  if (targetAgents.value.length === 1) {
    selectedAgentId.value = targetAgents.value[0].id;
  }
  if (voiceInboxes.value.length === 1) {
    selectedInboxId.value = voiceInboxes.value[0].id;
  }
};

const openDialog = async () => {
  setDefaults();
  if (!shouldPrompt.value) {
    // eslint-disable-next-line no-console
    console.log('[InternalVoiceCall] start without prompt', {
      conversationId: props.conversation.id,
      selectedInboxId: selectedInboxId.value,
      selectedAgentId: selectedAgentId.value,
    });
    await startCall();
    return;
  }
  // eslint-disable-next-line no-console
  console.log('[InternalVoiceCall] open dialog', {
    conversationId: props.conversation.id,
  });
  dialogRef.value?.open();
};

const startCall = async () => {
  if (!selectedAgentId.value || !selectedInboxId.value || isCalling.value) {
    return;
  }

  isCalling.value = true;
  // eslint-disable-next-line no-console
  console.log('[InternalVoiceCall] startCall', {
    conversationId: props.conversation.id,
    selectedInboxId: selectedInboxId.value,
    selectedAgentId: selectedAgentId.value,
  });
  try {
    const response = await InternalConversationsAPI.initiateVoiceCall({
      conversationId: props.conversation.id,
      voiceInboxId: selectedInboxId.value,
      targetAgentId: selectedAgentId.value,
    });
    const {
      call_sid: callSid,
      conversation_id: conversationId,
      inbox_id: inboxId,
    } = response?.data || {};

    if (callSid && conversationId) {
      // eslint-disable-next-line no-console
      console.log('[InternalVoiceCall] call initiated', {
        callSid,
        conversationId,
        inboxId,
      });
      callsStore.addCall({
        callSid,
        conversationId,
        inboxId,
        callDirection: 'outbound',
      });
    }

    useAlert(t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_INITIATED'));
    dialogRef.value?.close();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[InternalVoiceCall] startCall error', { error });
    useAlert(t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_FAILED'));
  } finally {
    isCalling.value = false;
  }
};
</script>

<template>
  <span v-if="shouldRender" class="contents">
    <Button
      :label="$t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_BUTTON')"
      icon="i-ph-phone-bold"
      size="sm"
      :disabled="isCalling"
      :is-loading="isCalling"
      @click="openDialog"
    />

    <Dialog
      v-if="shouldPrompt"
      ref="dialogRef"
      :title="$t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_TITLE')"
      show-cancel-button
      :show-confirm-button="false"
      width="md"
    >
      <div class="flex flex-col gap-4">
        <label v-if="targetAgents.length > 1" class="flex flex-col gap-2">
          <span class="text-sm text-n-slate-11">
            {{ $t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_PICK_AGENT') }}
          </span>
          <select
            v-model="selectedAgentId"
            class="rounded-md border border-n-strong bg-transparent px-3 py-2 text-sm"
          >
            <option disabled value="">--</option>
            <option
              v-for="agent in targetAgents"
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
            v-model="selectedInboxId"
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

        <div class="flex justify-end">
          <Button
            :label="$t('CONVERSATION.VOICE_WIDGET.INTERNAL_CALL_START')"
            :disabled="!selectedAgentId || !selectedInboxId"
            :is-loading="isCalling"
            @click="startCall"
          />
        </div>
      </div>
    </Dialog>
  </span>
</template>
