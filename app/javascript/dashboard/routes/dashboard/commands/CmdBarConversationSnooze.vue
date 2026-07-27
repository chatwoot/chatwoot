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
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';
import { useFormatBusinessRuleError } from 'dashboard/composables/useFormatBusinessRuleError';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const showCustomSnoozeModal = ref(false);
const { checkStatusChange } = useBusinessRulesStatusGuard();
const formatBusinessRuleError = useFormatBusinessRuleError();

const selectedChat = computed(() => getters.getSelectedChat.value);
const contextMenuChatId = computed(() => getters.getContextMenuChatId.value);

const activeConversation = computed(() => {
  const id = selectedChat.value?.id || contextMenuChatId.value;
  if (!id) return selectedChat.value;
  if (selectedChat.value?.id === id) return selectedChat.value;
  return getters.getConversationById.value(id) || selectedChat.value;
});

const canProceedWithSnooze = () => {
  const conversation = activeConversation.value;
  if (!conversation) return false;

  const guard = checkStatusChange(
    conversation,
    wootConstants.STATUS_TYPE.SNOOZED
  );
  if (guard.forbiddenLabels?.length) {
    useAlert(
      t('BUSINESS_RULES.STATUS_ERRORS.forbidden_label', {
        label: guard.forbiddenLabels[0],
      })
    );
    return false;
  }
  if (guard.needsAssignee) {
    useAlert(t('BUSINESS_RULES.STATUS_ERRORS.missing_assignee'));
    return false;
  }
  if (guard.missingAttributes?.length) {
    const keys = guard.missingAttributes
      .map(a => a.label || a.value)
      .join(', ');
    useAlert(
      t('BUSINESS_RULES.STATUS_ERRORS.missing_attribute', { key: keys })
    );
    return false;
  }
  return true;
};

const toggleStatus = async (status, snoozedUntil) => {
  if (!canProceedWithSnooze()) {
    store.dispatch('setContextMenuChatId', null);
    return;
  }

  try {
    await store.dispatch('toggleStatus', {
      conversationId: selectedChat.value?.id || contextMenuChatId.value,
      status,
      snoozedUntil,
    });
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  } catch (error) {
    const serverMessage =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      error?.message;
    useAlert(
      formatBusinessRuleError(serverMessage) ||
        t('CONVERSATION.CHANGE_STATUS_FAILED')
    );
  } finally {
    store.dispatch('setContextMenuChatId', null);
  }
};

const onCmdSnoozeConversation = snoozeType => {
  if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
    showCustomSnoozeModal.value = true;
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
  showCustomSnoozeModal.value = false;
  if (customSnoozeTime) {
    toggleStatus(
      wootConstants.STATUS_TYPE.SNOOZED,
      getUnixTime(customSnoozeTime)
    );
  }
};

const hideCustomSnoozeModal = () => {
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
