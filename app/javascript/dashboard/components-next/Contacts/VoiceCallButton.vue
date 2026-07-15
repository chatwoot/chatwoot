<script setup>
import { computed, ref, useAttrs } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import {
  isVoiceCallEnabled,
  getVoiceCallProvider,
  VOICE_CALL_PROVIDERS,
} from 'dashboard/helper/inbox';
import {
  VOICE_CALL_DIRECTION,
  VOICE_CALL_OUTBOUND_INIT_STATUS,
} from 'dashboard/components-next/message/constants';
import { useAlert } from 'dashboard/composables';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { useCallsStore } from 'dashboard/stores/calls';
import { useWhatsappCallSession } from 'dashboard/composables/useWhatsappCallSession';
import ContactAPI from 'dashboard/api/contacts';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  phone: { type: String, default: '' },
  contactId: { type: [String, Number], required: true },
  // When set, the WhatsApp call continues in this conversation (matching the
  // header button) instead of looking up the contact's most recent one.
  conversationId: { type: [String, Number], default: null },
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

const callsStore = useCallsStore();
const inboxesList = useMapGetter('inboxes/getInboxes');
const contactsUiFlags = useMapGetter('contacts/getUIFlags');

const voiceInboxes = computed(() =>
  (inboxesList.value || []).filter(isVoiceCallEnabled)
);
const hasVoiceInboxes = computed(() => voiceInboxes.value.length > 0);

const shouldRender = computed(() => hasVoiceInboxes.value && !!props.phone);

const isInitiatingCall = computed(() => {
  return contactsUiFlags.value?.isInitiatingCall || false;
});

// Mirror the conversation-header button: block a new call whenever any provider
// call is already active or ringing, otherwise starting a WhatsApp call here
// would leave a still-live Twilio (or other) session with no visible control.
const isCallButtonDisabled = computed(
  () =>
    callsStore.hasActiveCall ||
    callsStore.hasIncomingCall ||
    isInitiatingCall.value
);

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

const whatsappCallSession = useWhatsappCallSession();

// Find the most recent open conversation for this contact in the picked inbox.
// WhatsApp /initiate is conversation-scoped (unlike Twilio's contact-scoped path).
// Pass inboxId so the BE applies the filter before the 20-row cap — without it,
// contacts whose latest WhatsApp conversation falls outside the 20 most recent
// across all inboxes would be treated as having no conversation.
const findWhatsappConversationId = async inboxId => {
  const { data } = await ContactAPI.getConversations(props.contactId, {
    inboxId,
  });
  const conversations = data?.payload || [];
  const match = [...conversations].sort(
    (a, b) => (b.last_activity_at || 0) - (a.last_activity_at || 0)
  )[0];
  return match?.id || null;
};

const startWhatsappCall = async (inboxId, conversationIdHint) => {
  // WhatsApp /initiate is conversation-scoped, so we must hand it a
  // conversation. Use the caller's hint when given (in-conversation flow);
  // otherwise pick the most recent one in the inbox.
  const conversationId =
    conversationIdHint || (await findWhatsappConversationId(inboxId));
  if (!conversationId) {
    useAlert(t('CONTACT_PANEL.CALL_FAILED'));
    return;
  }

  const response =
    await whatsappCallSession.initiateOutboundCall(conversationId);
  // The composable returns { status: 'locked' } when an init is already in
  // flight or a call is already active; treat that as a soft no-op rather than
  // claiming success.
  if (response?.status === VOICE_CALL_OUTBOUND_INIT_STATUS.LOCKED) return;
  if (!response?.id) {
    // Permission template path returns no call id. Mirror the header button and
    // surface whether the request was just sent or is already pending instead of
    // claiming the call started. The permission message lands in the
    // conversation, so still navigate there.
    const messageKey =
      response?.status === VOICE_CALL_OUTBOUND_INIT_STATUS.PERMISSION_PENDING
        ? 'CONTACT_PANEL.WHATSAPP_CALL_PERMISSION_PENDING'
        : 'CONTACT_PANEL.WHATSAPP_CALL_PERMISSION_REQUESTED';
    useAlert(t(messageKey));
    navigateToConversation(conversationId);
    return;
  }

  // Stay non-active until the connect cable event arrives — flipping to active
  // here would start the duration timer before the contact picks up.
  callsStore.addCall({
    callSid: response.call_id,
    callId: response.id,
    conversationId,
    inboxId,
    callDirection: VOICE_CALL_DIRECTION.OUTBOUND,
    provider: VOICE_CALL_PROVIDERS.WHATSAPP,
  });

  useAlert(t('CONTACT_PANEL.CALL_INITIATED'));
  navigateToConversation(conversationId);
};

const startCall = async (inboxId, conversationIdHint = null) => {
  if (isCallButtonDisabled.value) return;

  const inbox = (inboxesList.value || []).find(i => i.id === inboxId);
  if (getVoiceCallProvider(inbox) === VOICE_CALL_PROVIDERS.WHATSAPP) {
    try {
      await startWhatsappCall(inboxId, conversationIdHint);
    } catch (error) {
      useAlert(error?.message || t('CONTACT_PANEL.CALL_FAILED'));
    }
    return;
  }

  try {
    const response = await store.dispatch('contacts/initiateCall', {
      contactId: props.contactId,
      inboxId,
      conversationId: conversationIdHint,
    });
    const { call_sid: callSid, conversation_id: conversationId } = response;

    callsStore.addCall({
      callSid,
      conversationId,
      inboxId,
      callDirection: VOICE_CALL_DIRECTION.OUTBOUND,
    });

    useAlert(t('CONTACT_PANEL.CALL_INITIATED'));
    navigateToConversation(response?.conversation_id);
  } catch (error) {
    const apiError = error?.message;
    useAlert(apiError || t('CONTACT_PANEL.CALL_FAILED'));
  }
};

const onClick = async () => {
  // In conversation context, only stay in this conversation if its inbox is
  // itself voice-capable (works the same for Twilio and WhatsApp). For
  // non-voice channels (email, web, …) fall back to the picker so the call
  // goes out via a voice inbox.
  if (props.conversationId) {
    const conversation = store.getters.getConversationById(
      props.conversationId
    );
    const conversationInbox = (inboxesList.value || []).find(
      i => i.id === conversation?.inbox_id
    );
    if (conversationInbox && isVoiceCallEnabled(conversationInbox)) {
      await startCall(conversationInbox.id, props.conversationId);
      return;
    }
  }
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
      :disabled="isCallButtonDisabled"
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
