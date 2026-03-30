<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import BackButton from '../BackButton.vue';
import InboxName from '../InboxName.vue';
import MoreActions from './MoreActions.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useInbox } from 'dashboard/composables/useInbox';
import { useI18n } from 'vue-i18n';
import WhatsappCallsAPI from 'dashboard/api/whatsappCalls';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  useWhatsappCallsStore,
  setOutboundCallProperty,
} from 'dashboard/stores/whatsappCalls';
import { startCallRecording } from 'dashboard/composables/useWhatsappCallSession';

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
const { isAWebWidgetInbox, isAWhatsAppCloudChannel } = useInbox();
const whatsappCallsStore = useWhatsappCallsStore();
const isInitiatingCall = ref(false);

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

const canInitiateWhatsappCall = computed(() => {
  if (!isAWhatsAppCloudChannel.value) return false;
  if (!inbox.value?.calling_enabled) return false;
  // Block if there's already an active or ringing WhatsApp call
  if (whatsappCallsStore.hasWhatsappCall) return false;
  return true;
});

const waitForOutboundIceGathering = pc =>
  new Promise(resolve => {
    if (pc.iceGatheringState === 'complete') {
      resolve();
      return;
    }
    const timeout = setTimeout(() => resolve(), 10000);
    pc.onicegatheringstatechange = () => {
      if (pc.iceGatheringState === 'complete') {
        clearTimeout(timeout);
        resolve();
      }
    };
  });

const initiateWhatsappCall = async () => {
  if (isInitiatingCall.value || !currentChat.value?.id) return;
  isInitiatingCall.value = true;
  let pc = null;
  let localStream = null;
  let waCallId = null;
  try {
    localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
    pc = new RTCPeerConnection({
      iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
    });
    localStream.getTracks().forEach(track => pc.addTrack(track, localStream));

    // Handle remote audio from Meta — ontrack fires when the callee picks up
    pc.ontrack = event => {
      const [stream] = event.streams;
      if (!stream) return;
      const audio = document.createElement('audio');
      audio.srcObject = stream;
      audio.autoplay = true;
      document.body.appendChild(audio);
      setOutboundCallProperty('audio', audio);
      // Remote audio arrived — callee picked up, transition from ringing to connected
      whatsappCallsStore.markActiveCallConnected();
      // Start recording both local + remote audio
      if (waCallId) startCallRecording(pc, localStream, waCallId);
    };

    pc.oniceconnectionstatechange = () => {
      // eslint-disable-next-line no-console
      console.log('[WhatsApp Call] Outbound ICE state:', pc.iceConnectionState);
    };

    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    // Wait for ICE gathering to complete before sending offer
    await waitForOutboundIceGathering(pc);
    const completeSdp = pc.localDescription.sdp;

    const response = await WhatsappCallsAPI.initiate(
      currentChat.value.id,
      completeSdp
    );

    const callStatus = response.data?.status;
    if (
      callStatus === 'permission_requested' ||
      callStatus === 'permission_pending'
    ) {
      pc.close();
      localStream.getTracks().forEach(track => track.stop());
      const message =
        callStatus === 'permission_requested'
          ? t('WHATSAPP_CALL.PERMISSION_REQUESTED')
          : t('WHATSAPP_CALL.PERMISSION_PENDING');
      emitter.emit(BUS_EVENTS.SHOW_ALERT, { message, type: 'info' });
      return;
    }

    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: t('WHATSAPP_CALL.CALLING'),
      type: 'success',
    });

    const outboundCallId = response.data?.call_id;
    waCallId = response.data?.id;
    setOutboundCallProperty('pc', pc);
    setOutboundCallProperty('stream', localStream);
    setOutboundCallProperty('callId', outboundCallId);

    // Set active call in store so the WhatsappCallWidget renders
    // Status starts as 'ringing' — updated to 'connected' when SDP answer arrives
    whatsappCallsStore.setActiveCall({
      id: response.data?.id,
      callId: outboundCallId,
      direction: 'outbound',
      status: 'ringing',
      conversationId: currentChat.value.id,
      caller: {
        name: currentContact.value?.name,
        phone: currentContact.value?.phone_number,
        avatar: currentContact.value?.thumbnail,
      },
    });
  } catch (err) {
    if (pc) pc.close();
    if (localStream) localStream.getTracks().forEach(track => track.stop());
    const errorMessage =
      err.response?.data?.error || t('WHATSAPP_CALL.CALL_FAILED');
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: errorMessage,
      type: 'error',
    });
  } finally {
    isInitiatingCall.value = false;
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
          class="flex items-center gap-2 overflow-hidden text-xs conversation--header--actions text-ellipsis whitespace-nowrap"
        >
          <InboxName v-if="hasMultipleInboxes" :inbox="inbox" class="!mx-0" />
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
      <button
        v-if="canInitiateWhatsappCall"
        v-tooltip="$t('WHATSAPP_CALL.INITIATE_CALL')"
        class="flex items-center justify-center w-8 h-8 rounded-lg text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 transition-colors"
        :disabled="isInitiatingCall"
        @click="initiateWhatsappCall"
      >
        <i
          v-if="isInitiatingCall"
          class="text-base i-ph-circle-notch animate-spin"
        />
        <i v-else class="text-base i-ph-phone-bold" />
      </button>
      <MoreActions :conversation-id="currentChat.id" />
    </div>
  </div>
</template>
