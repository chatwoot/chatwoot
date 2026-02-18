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
const isAlooAIHandling = computed(() => {
  // AI is handling if: inbox has active Aloo assistant AND no human assignee
  return alooAssistant.value?.active && !assignedAgent.value;
});
const hasAlooAssistant = computed(
  () => alooAssistant.value?.id && alooAssistant.value?.active
);

// Human assistance requested (customer asked for human, AI still responding)
const isHumanAssistanceRequested = computed(
  () =>
    currentChat.value?.custom_attributes?.human_assistance_requested === true
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

// Show "Human Assistance Requested" banner when flag is set and AI is still handling
const showHumanAssistanceRequestedBanner = computed(() => {
  return (
    isHumanAssistanceRequested.value &&
    isAlooAIHandling.value &&
    isCurrentUserHuman.value &&
    !props.isOnPrivateNote
  );
});

// Show "Return to AI" banner when human is handling (has human assignee)
const isHumanHandling = computed(() => {
  return assignedAgent.value && !assignedAgent.value.is_ai;
});

const showAlooReturnToAIBanner = computed(() => {
  return (
    hasAlooAssistant.value &&
    isHumanHandling.value &&
    isCurrentUserHuman.value &&
    !props.isOnPrivateNote
  );
});

// Show "Assign to AI" banner when AI is NOT handling (human handling or unassigned)
const showAlooAssignToAIBanner = computed(() => {
  return (
    hasAlooAssistant.value &&
    !isAlooAIHandling.value &&
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

// Aloo: Return conversation to AI (unassign human)
const onClickAlooReturnToAI = async () => {
  try {
    assignedAgent.value = null;
    useAlert(t('CONVERSATION.ALOO.RETURN_TO_AI_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.RETURN_TO_AI_ERROR'));
  }
};

// Aloo: Assign conversation to AI (unassign human)
const onClickAlooAssignToAI = async () => {
  try {
    assignedAgent.value = null;
    useAlert(t('CONVERSATION.ALOO.ASSIGN_TO_AI_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.ASSIGN_TO_AI_ERROR'));
  }
};

// Take over from human assistance request: clears assistance request, assigns to current user
const onClickTakeOverFromAssistanceRequest = async () => {
  try {
    await store.dispatch('updateCustomAttributes', {
      conversationId: currentChat.value?.id,
      customAttributes: {
        ...currentChat.value?.custom_attributes,
        human_assistance_requested: false,
        human_assistance_handled_at: new Date().toISOString(),
      },
    });
    // Assign to current user (this alone stops AI from responding)
    await selfAssignConversation();
    useAlert(t('CONVERSATION.ALOO.TAKE_OVER_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.TAKE_OVER_ERROR'));
  }
};

// Dismiss/ignore help request: clears assistance flag, AI continues handling
const onClickDismissAssistanceRequest = async () => {
  try {
    await store.dispatch('updateCustomAttributes', {
      conversationId: currentChat.value?.id,
      customAttributes: {
        ...currentChat.value?.custom_attributes,
        human_assistance_requested: false,
        human_assistance_dismissed_at: new Date().toISOString(),
      },
    });
    useAlert(t('CONVERSATION.ALOO.DISMISS_ASSISTANCE_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.DISMISS_ASSISTANCE_ERROR'));
  }
};
</script>

<template>
  <!-- Aloo: Human assistance requested banner (customer asked for human, AI still responding) -->
  <Banner
    v-if="showHumanAssistanceRequestedBanner"
    action-button-variant="ghost"
    color-scheme="warning"
    class="mx-2 mb-2 rounded-lg !py-3"
    :banner-message="
      $t('CONVERSATION.ALOO.HUMAN_ASSISTANCE_BANNER_MESSAGE', {
        assistantName: alooAssistant?.name,
      })
    "
    has-action-button
    action-button-icon="i-lucide-hand"
    :action-button-label="
      $t('CONVERSATION.ALOO.HUMAN_ASSISTANCE_TAKE_OVER_BUTTON')
    "
    has-close-button
    @primary-action="onClickTakeOverFromAssistanceRequest"
    @close="onClickDismissAssistanceRequest"
  />
  <!-- Aloo: Informational banner when AI is handling and user starts typing -->
  <Banner
    v-if="showAlooTakeOverBanner && !showHumanAssistanceRequestedBanner"
    color-scheme="primary"
    class="mx-2 mb-2 rounded-lg !py-3"
    :banner-message="
      $t('CONVERSATION.ALOO.AUTO_HANDOFF_MESSAGE', {
        assistantName: alooAssistant?.name,
      })
    "
  />
  <!-- Aloo: Return to AI banner (shown when human explicitly took over) -->
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
  <!-- Aloo: Assign to AI banner (shown when AI is NOT handling but could be) -->
  <Banner
    v-if="showAlooAssignToAIBanner && !showAlooReturnToAIBanner"
    action-button-variant="ghost"
    color-scheme="secondary"
    class="mx-2 mb-2 rounded-lg !py-3"
    :banner-message="
      $t('CONVERSATION.ALOO.ASSIGN_TO_AI_MESSAGE', {
        assistantName: alooAssistant?.name,
      })
    "
    has-action-button
    action-button-icon="i-lucide-bot"
    :action-button-label="$t('CONVERSATION.ALOO.ASSIGN_TO_AI_BUTTON')"
    @primary-action="onClickAlooAssignToAI"
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
