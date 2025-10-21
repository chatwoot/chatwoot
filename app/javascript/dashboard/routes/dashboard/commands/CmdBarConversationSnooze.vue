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
const showCustomSnoozeModal = ref(false);

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
    showCustomSnoozeModal.value = true;
  } else {
    toggleStatus(
      wootConstants.STATUS_TYPE.SNOOZED,
      findSnoozeTime(snoozeType) || null
    );
  }
};

const chooseSnoozeTime = customSnoozeTime => {
  showCustomSnoozeModal.value = false;
  if (customSnoozeTime) {
    toggleStatus(
      wootConstants.STATUS_TYPE.SNOOZED,
      getUnixTime(customSnoozeTime)
    );
  }
};

const hideCustomSnoozeModal = () => {
  // if we select custom snooze and the custom snooze modal is open
  // Then if the custom snooze modal is closed then set the context menu chat id to null
  store.dispatch('setContextMenuChatId', null);
  showCustomSnoozeModal.value = false;
};

useEmitter(CMD_SNOOZE_CONVERSATION, onCmdSnoozeConversation);
</script>

<template>
  <woot-modal
    v-model:show="showCustomSnoozeModal"
    :on-close="hideCustomSnoozeModal"
  >
    <CustomSnoozeModal
      @close="hideCustomSnoozeModal"
      @choose-time="chooseSnoozeTime"
    />
  </woot-modal>
</template>
