<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useEmitter } from 'dashboard/composables/emitter';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useConversationStatusActions } from 'dashboard/composables/useConversationStatusActions';
import wootConstants from 'dashboard/constants/globals';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

import Button from 'dashboard/components-next/button/Button.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';

const { t } = useI18n();
const {
  currentChat,
  isLoading,
  resolveAttributesModalRef,
  attemptStatusChange,
  handleResolveWithAttributes,
} = useConversationStatusActions();

const isOpen = computed(
  () => currentChat.value?.status === wootConstants.STATUS_TYPE.OPEN
);
const isResolved = computed(
  () => currentChat.value?.status === wootConstants.STATUS_TYPE.RESOLVED
);
const showOpenButton = computed(() => {
  const status = currentChat.value?.status;
  return (
    status === wootConstants.STATUS_TYPE.PENDING ||
    status === wootConstants.STATUS_TYPE.SNOOZED
  );
});

const getConversationParams = () => {
  const allConversations = document.querySelectorAll(
    '.conversations-list .conversation'
  );

  const activeConversation = document.querySelector(
    'div.conversations-list div.conversation.active'
  );
  const activeConversationIndex = [...allConversations].indexOf(
    activeConversation
  );
  const lastConversationIndex = allConversations.length - 1;

  return {
    all: allConversations,
    activeIndex: activeConversationIndex,
    lastIndex: lastConversationIndex,
  };
};

const onCmdOpenConversation = () => {
  attemptStatusChange(wootConstants.STATUS_TYPE.OPEN);
};

const onCmdResolveConversation = () => {
  attemptStatusChange(wootConstants.STATUS_TYPE.RESOLVED);
};

const keyboardEvents = {
  'Alt+KeyE': {
    action: async event => {
      event.preventDefault();
      onCmdResolveConversation();
    },
  },
  '$mod+Alt+KeyE': {
    action: async event => {
      const { all, activeIndex, lastIndex } = getConversationParams();
      onCmdResolveConversation();

      if (activeIndex < lastIndex) {
        all[activeIndex + 1].click();
      } else if (all.length > 1) {
        all[0].click();
        document.querySelector('.conversations-list').scrollTop = 0;
      }
      event.preventDefault();
    },
  },
};

useKeyboardEvents(keyboardEvents);

useEmitter(CMD_REOPEN_CONVERSATION, onCmdOpenConversation);
useEmitter(CMD_RESOLVE_CONVERSATION, onCmdResolveConversation);
</script>

<template>
  <div class="flex relative justify-end items-center resolve-actions">
    <Button
      v-if="isOpen"
      :label="t('CONVERSATION.HEADER.RESOLVE_ACTION')"
      size="sm"
      color="slate"
      no-animation
      class="rounded-lg shadow outline outline-1 outline-n-container !outline-offset-0"
      :is-loading="isLoading"
      @click="onCmdResolveConversation"
    />
    <Button
      v-else-if="isResolved"
      :label="t('CONVERSATION.HEADER.REOPEN_ACTION')"
      size="sm"
      color="slate"
      no-animation
      class="rounded-lg shadow outline outline-1 outline-n-container !outline-offset-0"
      :is-loading="isLoading"
      @click="onCmdOpenConversation"
    />
    <Button
      v-else-if="showOpenButton"
      :label="t('CONVERSATION.HEADER.OPEN_ACTION')"
      size="sm"
      color="slate"
      no-animation
      class="rounded-lg shadow"
      :is-loading="isLoading"
      @click="onCmdOpenConversation"
    />
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />
  </div>
</template>
