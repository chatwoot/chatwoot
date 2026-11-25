<script setup>
import { computed, onUnmounted } from 'vue';
import { useToggle } from '@vueuse/core';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import wootConstants from 'dashboard/constants/globals';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ResolveAction from '../../buttons/ResolveAction.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ConversationApi from 'dashboard/api/inbox/conversation';
import { isSessionLayerProvider } from 'dashboard/helper/whatsappSession';

import {
  CMD_MUTE_CONVERSATION,
  CMD_PIN_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
  CMD_UNPIN_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

// No props needed as we're getting currentChat from the store directly
const store = useStore();
const { t } = useI18n();

const [showEmailActionsModal, toggleEmailModal] = useToggle(false);
const [showActionsDropdown, toggleDropdown] = useToggle(false);

const currentChat = computed(() => store.getters.getSelectedChat);
const isPinnedGetter = useMapGetter('conversationPins/isPinned');
const isPinned = computed(() => isPinnedGetter.value(currentChat.value.id));
// Resolving drops the pins, so pinning a resolved conversation would only burn one of the five slots.
const canTogglePin = computed(
  () =>
    isPinned.value ||
    currentChat.value.status !== wootConstants.STATUS_TYPE.RESOLVED
);

const pin = async () => {
  try {
    await store.dispatch('conversationPins/pin', currentChat.value.id);
  } catch (error) {
    useAlert(error?.message ?? t('CONVERSATION.PIN.ERROR'));
  }
};

const unpin = async () => {
  try {
    await store.dispatch('conversationPins/unpin', currentChat.value.id);
  } catch (error) {
    useAlert(error?.message ?? t('CONVERSATION.PIN.ERROR'));
  }
};

const togglePin = () => {
  if (!canTogglePin.value) return undefined;

  return isPinned.value ? unpin() : pin();
};

useKeyboardEvents({
  'Alt+KeyI': { action: togglePin },
});

// The files of an imported history that the inbox's automatic fetch left behind, for one
// conversation: somebody reading an old group is who needs them.
const canFetchHistoryMedia = computed(() => {
  const inbox = store.getters['inboxes/getInbox'](currentChat.value.inbox_id);
  return isSessionLayerProvider(inbox?.provider);
});

const fetchHistoryMedia = async () => {
  try {
    await ConversationApi.fetchHistoryMedia(currentChat.value.id);
    useAlert(t('CONVERSATION.HISTORY_MEDIA.DOWNLOAD_ALL_REQUESTED'));
  } catch (error) {
    useAlert(t('CONVERSATION.HISTORY_MEDIA.DOWNLOAD_ALL_ERROR'));
  }
};
const autoTranslate = computed(() => store.getters.getAutoTranslate);

const actionMenuItems = computed(() => {
  const items = [];

  if (!currentChat.value.muted) {
    items.push({
      icon: 'i-lucide-volume-off',
      label: t('CONTACT_PANEL.MUTE_CONTACT'),
      action: 'mute',
      value: 'mute',
    });
  } else {
    items.push({
      icon: 'i-lucide-volume-1',
      label: t('CONTACT_PANEL.UNMUTE_CONTACT'),
      action: 'unmute',
      value: 'unmute',
    });
  }

  if (canTogglePin.value) {
    items.push({
      icon: isPinned.value ? 'i-lucide-pin-off' : 'i-lucide-pin',
      label: isPinned.value
        ? t('CONVERSATION.PIN.UNPIN')
        : t('CONVERSATION.PIN.PIN'),
      action: 'toggle_pin',
      value: 'toggle_pin',
    });
  }

  items.push({
    icon: 'i-lucide-share',
    label: t('CONTACT_PANEL.SEND_TRANSCRIPT'),
    action: 'send_transcript',
    value: 'send_transcript',
  });

  if (canFetchHistoryMedia.value) {
    items.push({
      icon: 'i-lucide-download',
      label: t('CONVERSATION.HISTORY_MEDIA.DOWNLOAD_ALL'),
      action: 'fetch_history_media',
      value: 'fetch_history_media',
    });
  }

  const { enabled, disabledInConversation, language } = autoTranslate.value;
  if (enabled) {
    items.push({
      icon: 'i-lucide-languages',
      label: disabledInConversation
        ? t('CONVERSATION.HEADER.AUTO_TRANSLATE.TURN_ON')
        : t('CONVERSATION.HEADER.AUTO_TRANSLATE.TURN_OFF'),
      hint: disabledInConversation ? '' : language,
      action: 'auto_translate',
      value: 'auto_translate',
    });
  }

  return items;
});

const toggleAutoTranslate = async () => {
  const disabled = !autoTranslate.value.disabledInConversation;
  try {
    await store.dispatch('setConversationAutoTranslate', {
      conversationId: currentChat.value.id,
      disabled,
    });
    useAlert(
      disabled
        ? t('CONVERSATION.HEADER.AUTO_TRANSLATE.TURNED_OFF')
        : t('CONVERSATION.HEADER.AUTO_TRANSLATE.TURNED_ON')
    );
  } catch {
    useAlert(t('CONVERSATION.HEADER.AUTO_TRANSLATE.UPDATE_FAILED'));
  }
};

const handleActionClick = ({ action }) => {
  toggleDropdown(false);

  if (action === 'mute') {
    store.dispatch('muteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
  } else if (action === 'unmute') {
    store.dispatch('unmuteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
  } else if (action === 'toggle_pin') {
    togglePin();
  } else if (action === 'send_transcript') {
    toggleEmailModal();
  } else if (action === 'fetch_history_media') {
    fetchHistoryMedia();
  } else if (action === 'auto_translate') {
    toggleAutoTranslate();
  }
};

// These functions are needed for the event listeners
const mute = () => {
  store.dispatch('muteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
};

const unmute = () => {
  store.dispatch('unmuteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
};

emitter.on(CMD_MUTE_CONVERSATION, mute);
emitter.on(CMD_UNMUTE_CONVERSATION, unmute);
emitter.on(CMD_PIN_CONVERSATION, pin);
emitter.on(CMD_UNPIN_CONVERSATION, unpin);

const openEmailModal = () => toggleEmailModal(true);
emitter.on(CMD_SEND_TRANSCRIPT, openEmailModal);

onUnmounted(() => {
  emitter.off(CMD_MUTE_CONVERSATION, mute);
  emitter.off(CMD_UNMUTE_CONVERSATION, unmute);
  emitter.off(CMD_PIN_CONVERSATION, pin);
  emitter.off(CMD_UNPIN_CONVERSATION, unpin);
  emitter.off(CMD_SEND_TRANSCRIPT, openEmailModal);
});
</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <ResolveAction
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <div
      v-on-clickaway="() => toggleDropdown(false)"
      class="relative flex items-center group"
    >
      <ButtonV4
        v-tooltip="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-vertical"
        class="rounded-md group-hover:bg-n-alpha-2"
        @click="toggleDropdown()"
      />
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="actionMenuItems"
        class="mt-1 ltr:right-0 rtl:left-0 top-full"
        @action="handleActionClick"
      >
        <template #trailing-icon="{ item }">
          <span
            v-if="item.hint"
            class="flex-shrink-0 ms-auto ps-4 text-sm text-n-slate-11"
          >
            {{ item.hint }}
          </span>
        </template>
      </DropdownMenu>
    </div>
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailModal"
    />
  </div>
</template>
