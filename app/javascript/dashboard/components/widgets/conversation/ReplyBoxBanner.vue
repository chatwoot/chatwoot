<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import wootConstants from 'dashboard/constants/globals';

import Banner from 'dashboard/components/ui/Banner.vue';

const props = defineProps({
  message: {
    type: String,
    default: '',
  },
  isOnPrivateNote: {
    type: Boolean,
    default: false,
  },
});

const store = useStore();
const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');

const assignedAgent = computed({
  get() {
    return currentChat.value?.meta?.assignee;
  },
  set(agent) {
    const agentId = agent ? agent.id : null;
    store.dispatch('setCurrentChatAssignee', agent);
    store.dispatch('assignAgent', {
      conversationId: currentChat.value?.id,
      agentId,
    });
  },
});

const isUserTyping = computed(
  () => props.message !== '' && !props.isOnPrivateNote
);
const isUnassigned = computed(() => !assignedAgent.value);
const isAssignedToOtherAgent = computed(
  () => assignedAgent.value?.id !== currentUser.value?.id
);

const isCurrentUserHuman = computed(() => !currentUser.value?.is_ai);

// Aloo AI Assistant handling
const alooAssistant = computed(() => currentChat.value?.aloo_assistant);
const isAlooHandoffActive = computed(
  () => currentChat.value?.custom_attributes?.aloo_handoff_active === true
);
const isAlooAIHandling = computed(() => {
  // AI is handling if: inbox has active Aloo assistant AND handoff is not active AND no human assignee
  return (
    alooAssistant.value?.active &&
    !isAlooHandoffActive.value &&
    !assignedAgent.value
  );
});
const hasAlooAssistant = computed(
  () => alooAssistant.value?.id && alooAssistant.value?.active
);

// Show "Take Over" banner when Aloo AI is handling and user starts typing
const showAlooTakeOverBanner = computed(() => {
  return (
    isAlooAIHandling.value &&
    isUserTyping.value &&
    isCurrentUserHuman.value &&
    !props.isOnPrivateNote
  );
});

// Show "Return to AI" banner when human is handling (has assignee or handoff active)
const isHumanHandling = computed(() => {
  // Human is handling if: there's a handoff flag OR there's a human assignee
  return (
    isAlooHandoffActive.value ||
    (assignedAgent.value && !assignedAgent.value.is_ai)
  );
});

const showAlooReturnToAIBanner = computed(() => {
  return (
    hasAlooAssistant.value &&
    isHumanHandling.value &&
    isCurrentUserHuman.value &&
    !props.isOnPrivateNote
  );
});

const showSelfAssignBanner = computed(() => {
  // Don't show self-assign banner when Aloo AI is handling
  if (isAlooAIHandling.value) return false;
  return (
    isUserTyping.value && (isUnassigned.value || isAssignedToOtherAgent.value)
  );
});

const showBotHandoffBanner = computed(
  () =>
    isUserTyping.value &&
    currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING
);

const botHandoffActionLabel = computed(() => {
  return assignedAgent.value?.id === currentUser.value?.id
    ? t('CONVERSATION.BOT_HANDOFF_REOPEN_ACTION')
    : t('CONVERSATION.BOT_HANDOFF_ACTION');
});

const selfAssignConversation = async () => {
  const { avatar_url, ...rest } = currentUser.value || {};
  assignedAgent.value = { ...rest, thumbnail: avatar_url };
};

const needsAssignmentToCurrentUser = computed(() => {
  return isUnassigned.value || isAssignedToOtherAgent.value;
});

const onClickSelfAssign = async () => {
  try {
    await selfAssignConversation();
    useAlert(t('CONVERSATION.CHANGE_AGENT'));
  } catch (error) {
    useAlert(t('CONVERSATION.CHANGE_AGENT_FAILED'));
  }
};

const reopenConversation = async () => {
  await store.dispatch('toggleStatus', {
    conversationId: currentChat.value?.id,
    status: wootConstants.STATUS_TYPE.OPEN,
  });
};

const onClickBotHandoff = async () => {
  try {
    await reopenConversation();

    if (needsAssignmentToCurrentUser.value) {
      await selfAssignConversation();
    }

    useAlert(t('CONVERSATION.BOT_HANDOFF_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.BOT_HANDOFF_ERROR'));
  }
};

// Aloo: Return conversation to AI (clear handoff flag, unassign)
const onClickAlooReturnToAI = async () => {
  try {
    // Clear the handoff flag to let AI respond again
    await store.dispatch('updateCustomAttributes', {
      conversationId: currentChat.value?.id,
      customAttributes: {
        ...currentChat.value?.custom_attributes,
        aloo_handoff_active: false,
        aloo_handoff_cleared_at: new Date().toISOString(),
      },
    });
    // Unassign the conversation
    assignedAgent.value = null;
    useAlert(t('CONVERSATION.ALOO.RETURN_TO_AI_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.RETURN_TO_AI_ERROR'));
  }
};
</script>

<template>
  <!-- Aloo: Informational banner when AI is handling and user starts typing -->
  <Banner
    v-if="showAlooTakeOverBanner"
    color-scheme="primary"
    class="mx-2 mb-2 rounded-lg !py-3"
    :banner-message="
      $t('CONVERSATION.ALOO.AUTO_HANDOFF_MESSAGE', {
        assistantName: alooAssistant?.name,
      })
    "
  />
  <!-- Aloo: Return to AI banner (shown when handoff is active) -->
  <Banner
    v-if="showAlooReturnToAIBanner"
    action-button-variant="ghost"
    color-scheme="secondary"
    class="mx-2 mb-2 rounded-lg !py-3"
    :banner-message="
      $t('CONVERSATION.ALOO.RETURN_TO_AI_MESSAGE', {
        assistantName: alooAssistant?.name,
      })
    "
    has-action-button
    action-button-icon="i-lucide-bot"
    :action-button-label="$t('CONVERSATION.ALOO.RETURN_TO_AI_BUTTON')"
    @primary-action="onClickAlooReturnToAI"
  />
  <Banner
    v-if="showSelfAssignBanner && !showBotHandoffBanner"
    action-button-variant="ghost"
    color-scheme="secondary"
    class="mx-2 mb-2 rounded-lg !py-2"
    :banner-message="$t('CONVERSATION.NOT_ASSIGNED_TO_YOU')"
    has-action-button
    :action-button-label="$t('CONVERSATION.ASSIGN_TO_ME')"
    @primary-action="onClickSelfAssign"
  />
  <Banner
    v-if="showBotHandoffBanner"
    action-button-variant="ghost"
    color-scheme="secondary"
    class="mx-2 mb-2 rounded-lg !py-2"
    :banner-message="$t('CONVERSATION.BOT_HANDOFF_MESSAGE')"
    has-action-button
    :action-button-label="botHandoffActionLabel"
    @primary-action="onClickBotHandoff"
  />
</template>
