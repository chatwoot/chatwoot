<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import BackButton from '../BackButton.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import InboxName from '../InboxName.vue';
import MoreActions from './MoreActions.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useInbox } from 'dashboard/composables/useInbox';
import {
  getVoiceCallProvider,
  VOICE_CALL_PROVIDERS,
} from 'dashboard/helper/inbox';
import { useWhatsappCallSession } from 'dashboard/composables/useWhatsappCallSession';
import { useCallsStore } from 'dashboard/stores/calls';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showBackButton: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const conversationHeader = ref(null);
const { width } = useElementSize(conversationHeader);
const { isAWebWidgetInbox } = useInbox();

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const chatMetadata = computed(() => props.chat.meta);

const backButtonUrl = computed(() => {
  const {
    params: { inbox_id: inboxId, label, teamId, id: customViewId },
    name,
  } = route;

  const conversationTypeMap = {
    conversation_through_mentions: 'mention',
    conversation_through_participating: 'participating',
    conversation_through_unattended: 'unattended',
  };
  return conversationListPageURL({
    accountId: accountId.value,
    inboxId,
    label,
    teamId,
    conversationType: conversationTypeMap[name],
    customViewId,
  });
});

const isHMACVerified = computed(() => {
  if (!isAWebWidgetInbox.value) {
    return true;
  }
  return chatMetadata.value.hmac_verified;
});

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

const isSnoozed = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.SNOOZED
);

const snoozedDisplayText = computed(() => {
  const { snoozed_until: snoozedUntil } = currentChat.value;
  if (snoozedUntil) {
    return `${t('CONVERSATION.HEADER.SNOOZED_UNTIL')} ${snoozedReopenTime(snoozedUntil)}`;
  }
  return t('CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_REPLY');
});

const inbox = computed(() => {
  const { inbox_id: inboxId } = props.chat;
  return store.getters['inboxes/getInbox'](inboxId);
});

const hasMultipleInboxes = computed(
  () => store.getters['inboxes/getInboxes'].length > 1
);

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

const callsStore = useCallsStore();
const whatsappCallSession = useWhatsappCallSession();
const contactsUiFlags = useMapGetter('contacts/getUIFlags');

const voiceCallProvider = computed(() => getVoiceCallProvider(inbox.value));
const isVoiceCallInbox = computed(() => voiceCallProvider.value !== null);
const isWhatsappVoiceInbox = computed(
  () => voiceCallProvider.value === VOICE_CALL_PROVIDERS.WHATSAPP
);

const isCallButtonDisabled = computed(() => {
  if (callsStore.hasActiveCall || callsStore.hasIncomingCall) return true;
  if (isWhatsappVoiceInbox.value) {
    return whatsappCallSession.isInitiating.value;
  }
  return contactsUiFlags.value?.isInitiatingCall || false;
});

const isCallButtonLoading = computed(() =>
  isWhatsappVoiceInbox.value
    ? whatsappCallSession.isInitiating.value
    : !!contactsUiFlags.value?.isInitiatingCall
);

const callButtonTooltip = computed(() =>
  isWhatsappVoiceInbox.value
    ? t('CONVERSATION.HEADER.WHATSAPP_CALL')
    : t('CONVERSATION.HEADER.VOICE_CALL')
);

const startWhatsappCall = async () => {
  if (whatsappCallSession.isInitiating.value) return;
  try {
    const response = await whatsappCallSession.initiateOutboundCall(
      currentChat.value.id
    );

    // Composable returns { status: 'locked' } when init is already in flight or
    // a call is active; soft no-op so a parallel click doesn't trigger a banner.
    if (response?.status === 'locked') return;
    // Permission template path returns no call id — show banner, no widget yet.
    if (!response?.id) {
      const status = response?.status;
      const messageKey =
        status === 'permission_pending'
          ? 'CONVERSATION.HEADER.WHATSAPP_CALL_PERMISSION_PENDING'
          : 'CONVERSATION.HEADER.WHATSAPP_CALL_PERMISSION_REQUESTED';
      useAlert(t(messageKey));
      return;
    }

    // Stay non-active until Meta delivers the connect webhook (sdp_answer);
    // flipping to active here would start the duration timer before pickup.
    callsStore.addCall({
      callSid: response.call_id,
      callId: response.id,
      conversationId: currentChat.value.id,
      inboxId: inbox.value?.id,
      callDirection: 'outbound',
      provider: 'whatsapp',
    });
  } catch (error) {
    useAlert(error?.message || t('CONVERSATION.HEADER.WHATSAPP_CALL_FAILED'));
  }
};

const startTwilioCall = async () => {
  if (contactsUiFlags.value?.isInitiatingCall) return;
  try {
    const response = await store.dispatch('contacts/initiateCall', {
      contactId: currentContact.value.id,
      inboxId: inbox.value?.id,
      conversationId: currentChat.value.id,
    });

    callsStore.addCall({
      callSid: response?.call_sid,
      conversationId: response?.conversation_id ?? currentChat.value.id,
      inboxId: inbox.value?.id,
      callDirection: 'outbound',
    });
  } catch (error) {
    useAlert(error?.message || t('CONVERSATION.HEADER.VOICE_CALL_FAILED'));
  }
};

const startCall = () => {
  if (isWhatsappVoiceInbox.value) return startWhatsappCall();
  return startTwilioCall();
};

const copyConversationId = async () => {
  try {
    await copyTextToClipboard(String(props.chat.id));
    useAlert(t('CONVERSATION.HEADER.COPY_ID_SUCCESS'));
  } catch (error) {
    // error
  }
};
</script>

<template>
  <div
    ref="conversationHeader"
    class="flex flex-col gap-3 items-center justify-between flex-1 w-full min-w-0 xl:flex-row px-3 pt-3 pb-2 h-24 xl:h-12"
  >
    <div
      class="flex items-center justify-start w-full xl:w-auto max-w-full min-w-0 xl:flex-1"
    >
      <BackButton
        v-if="showBackButton"
        :back-url="backButtonUrl"
        class="ltr:mr-2 rtl:ml-2"
      />
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="32"
        :status="currentContact.availability_status"
        hide-offline-status
        rounded-full
      />
      <div
        class="flex flex-col items-start min-w-0 ml-2 overflow-hidden rtl:ml-0 rtl:mr-2"
      >
        <div class="flex flex-row items-center max-w-full gap-1 p-0 m-0">
          <span
            class="text-sm font-medium truncate leading-tight text-n-slate-12"
          >
            {{ currentContact.name }}
          </span>
          <fluent-icon
            v-if="!isHMACVerified"
            v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
            size="14"
            class="text-n-amber-10 my-0 mx-0 min-w-[14px] flex-shrink-0"
            icon="warning"
          />
        </div>

        <div
          class="flex items-center gap-1 overflow-hidden text-xs conversation--header--actions text-n-slate-11 text-ellipsis whitespace-nowrap"
        >
          <button
            type="button"
            class="truncate text-label-small text-n-slate-11 hover:text-n-slate-12 !p-0 cucursor-pointer"
            @click="copyConversationId"
          >
            {{ `#${chat.id}` }}
          </button>
          <span v-if="hasMultipleInboxes">•</span>
          <InboxName v-if="hasMultipleInboxes" :inbox="inbox" class="!mx-0" />
          <span v-if="isSnoozed">•</span>
          <span v-if="isSnoozed" class="font-medium text-n-amber-10">
            {{ snoozedDisplayText }}
          </span>
        </div>
      </div>
    </div>
    <div
      class="flex flex-row items-center justify-start xl:justify-end flex-shrink-0 gap-2 w-full xl:w-auto header-actions-wrap"
    >
      <SLACardLabel
        v-if="hasSlaPolicyId"
        :chat="chat"
        show-extended-info
        :parent-width="width"
        class="hidden md:flex"
      />
      <ButtonV4
        v-if="isVoiceCallInbox"
        v-tooltip.bottom="callButtonTooltip"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-phone"
        :is-loading="isCallButtonLoading"
        :disabled="isCallButtonDisabled"
        class="rounded-md hover:bg-n-alpha-2"
        @click="startCall"
      />
      <MoreActions :conversation-id="currentChat.id" />
    </div>
  </div>
</template>
