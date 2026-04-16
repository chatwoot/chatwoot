<script setup>
import { computed, ref, useAttrs } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { useAlert } from 'dashboard/composables';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { useCallsStore } from 'dashboard/stores/calls';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  phone: { type: String, default: '' },
  contactId: { type: [String, Number], required: true },
  label: { type: String, default: '' },
  icon: { type: [String, Object, Function], default: '' },
  size: { type: String, default: 'sm' },
  tooltipLabel: { type: String, default: '' },
});

defineOptions({ inheritAttrs: false });
const attrs = useAttrs();
const route = useRoute();
const router = useRouter();
const store = useStore();

const { t } = useI18n();

const dialogRef = ref(null);

const inboxesList = useMapGetter('inboxes/getInboxes');
const contactsUiFlags = useMapGetter('contacts/getUIFlags');

const voiceInboxes = computed(() =>
  (inboxesList.value || []).filter(
    inbox => inbox.channel_type === INBOX_TYPES.VOICE
  )
);
const hasVoiceInboxes = computed(() => voiceInboxes.value.length > 0);

// Unified behavior: hide when no phone
const shouldRender = computed(() => hasVoiceInboxes.value && !!props.phone);

const isInitiatingCall = computed(() => {
  return contactsUiFlags.value?.isInitiatingCall || false;
});

const navigateToConversation = conversationId => {
  const accountId = route.params.accountId;
  if (conversationId && accountId) {
    const path = frontendURL(
      conversationUrl({
        accountId,
        id: conversationId,
      })
    );
    router.push({ path });
  }
};

const startCall = async inboxId => {
  if (isInitiatingCall.value) return;

  try {
    const response = await store.dispatch('contacts/initiateCall', {
      contactId: props.contactId,
      inboxId,
    });
    const { call_sid: callSid, conversation_id: conversationId } = response;

    // Add call to store immediately so widget shows
    const callsStore = useCallsStore();
    callsStore.addCall({
      callSid,
      conversationId,
      inboxId,
      callDirection: 'outbound',
    });

    useAlert(t('CONTACT_PANEL.CALL_INITIATED'));
    navigateToConversation(response?.conversation_id);
  } catch (error) {
    const apiError = error?.message;
    useAlert(apiError || t('CONTACT_PANEL.CALL_FAILED'));
  }
};

const onClick = async () => {
  if (voiceInboxes.value.length > 1) {
    dialogRef.value?.open();
    return;
  }
  const [inbox] = voiceInboxes.value;
  await startCall(inbox.id);
};

const onPickInbox = async inbox => {
  dialogRef.value?.close();
  await startCall(inbox.id);
};
</script>

<template>
  <span class="contents">
    <Button
      v-if="shouldRender"
      v-tooltip.top-end="tooltipLabel || null"
      v-bind="attrs"
      :disabled="isInitiatingCall"
      :is-loading="isInitiatingCall"
      :label="label"
      :icon="icon"
      :size="size"
      @click="onClick"
    />

    <Dialog
      v-if="shouldRender && voiceInboxes.length > 1"
      ref="dialogRef"
      :title="$t('CONTACT_PANEL.VOICE_INBOX_PICKER.TITLE')"
      show-cancel-button
      :show-confirm-button="false"
      width="md"
    >
      <div class="flex flex-col gap-2">
        <button
          v-for="inbox in voiceInboxes"
          :key="inbox.id"
          type="button"
          class="flex items-center justify-between w-full px-4 py-2 text-left rounded-lg hover:bg-n-alpha-2"
          @click="onPickInbox(inbox)"
        >
          <div class="flex items-center gap-2">
            <span class="i-ri-phone-fill text-n-slate-10" />
            <span class="text-sm text-n-slate-12">{{ inbox.name }}</span>
          </div>
          <span v-if="inbox.phone_number" class="text-xs text-n-slate-10">
            {{ inbox.phone_number }}
          </span>
        </button>
      </div>
    </Dialog>
  </span>
</template>
