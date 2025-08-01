<script setup>
import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useEmitter } from 'dashboard/composables/emitter';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import wootConstants from 'dashboard/constants/globals';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const emitter = useEmitter();

const isLoading = ref(false);
const currentChat = computed(() => getters.getSelectedChat.value);
const currentUser = computed(() => getters.getCurrentUser.value);

const conversationStatus = computed(() => {
  if (currentChat.value.status === 'resolved' || currentChat.value.status === 'closed') {
    return 'closed';
  }
  if (currentChat.value.status === 'pending') {
    return 'ai_managed';
  }
  if (currentChat.value.meta.assignee) {
    return 'open';
  }
  return 'unassigned';
});

const buttonText = computed(() => {
  const key = {
    closed: 'CONVERSATION.HEADER.REOPEN_ACTION',
    open: 'CONVERSATION.HEADER.RESOLVE_ACTION',
    ai_managed: 'CONVERSATION.HEADER.RESOLVE_ACTION',
    unassigned: 'CONVERSATION.HEADER.ASSIGN_TO_ME',
  }[conversationStatus.value];
  return t(key);
});

const handleButtonClick = () => {
  const status = conversationStatus.value;
  if (status === 'closed') {
    toggleStatus(wootConstants.STATUS_TYPE.OPEN);
  } else if (status === 'open' || status === 'ai_managed') {
    toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
  } else if (status === 'unassigned') {
    assignToMe();
  }
};

const assignToMe = () => {
  isLoading.value = true;
  store
    .dispatch('assignAgent', {
      conversationId: currentChat.value.id,
      agentId: currentUser.value.id,
    })
    .then(() => {
      useAlert(t('CONVERSATION.CHANGE_STATUS'));
      isLoading.value = false;
    });
};

const toggleStatus = (status, snoozedUntil) => {
  isLoading.value = true;
  store
    .dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status,
      snoozedUntil,
    })
    .then(() => {
      useAlert(t('CONVERSATION.CHANGE_STATUS'));
      isLoading.value = false;
    });
};

const onCmdOpenConversation = () => {
  toggleStatus(wootConstants.STATUS_TYPE.OPEN);
};

const onCmdResolveConversation = () => {
  toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
};

useEmitter(CMD_REOPEN_CONVERSATION, onCmdOpenConversation);
useEmitter(CMD_RESOLVE_CONVERSATION, onCmdResolveConversation);
</script>

<template>
  <div class="relative flex items-center justify-end resolve-actions">
    <Button
      :label="buttonText"
      size="sm"
      color="slate"
      :is-loading="isLoading"
      @click="handleButtonClick"
    />
  </div>
</template>

<style lang="scss" scoped>
.dropdown-pane {
  .dropdown-menu__item {
    @apply mb-0;
  }
}
</style>
