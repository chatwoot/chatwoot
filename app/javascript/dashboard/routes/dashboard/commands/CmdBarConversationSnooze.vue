<script setup>
import { ref, computed } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useEmitter } from 'dashboard/composables/emitter';
import { getUnixTime } from 'date-fns';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { CMD_SNOOZE_CONVERSATION } from 'dashboard/helper/commandbar/events';
import wootConstants from 'dashboard/constants/globals';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const snoozeModalRef = ref(null);

const selectedChat = computed(() => getters.getSelectedChat.value);
const contextMenuChatId = computed(() => getters.getContextMenuChatId.value);

const toggleStatus = async (status, snoozedUntil) => {
  await store.dispatch('toggleStatus', {
    conversationId: selectedChat.value?.id || contextMenuChatId.value,
    status,
    snoozedUntil,
  });
  store.dispatch('setContextMenuChatId', null);
  useAlert(t('CONVERSATION.CHANGE_STATUS'));
};

const onCmdSnoozeConversation = snoozeType => {
  if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
    snoozeModalRef.value?.open();
  } else if (typeof snoozeType === 'number') {
    toggleStatus(wootConstants.STATUS_TYPE.SNOOZED, snoozeType);
  } else {
    toggleStatus(
      wootConstants.STATUS_TYPE.SNOOZED,
      findSnoozeTime(snoozeType) || null
    );
  }
};

const chooseSnoozeTime = customSnoozeTime => {
  if (customSnoozeTime) {
    toggleStatus(
      wootConstants.STATUS_TYPE.SNOOZED,
      getUnixTime(customSnoozeTime)
    );
  }
};

const clearContextMenu = () => {
  store.dispatch('setContextMenuChatId', null);
};

useEmitter(CMD_SNOOZE_CONVERSATION, onCmdSnoozeConversation);
</script>

<template>
  <CustomSnoozeModal
    ref="snoozeModalRef"
    @choose-time="chooseSnoozeTime"
    @close="clearContextMenu"
  />
</template>
