<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { isAIAssigneeType } from 'dashboard/helper/agentHelper';
import ConversationApi from 'dashboard/api/inbox/conversation';
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

const assignedAgent = computed(() => currentChat.value?.meta?.assignee);

const showSelfAssignBanner = computed(
  () =>
    props.message !== '' &&
    !props.isOnPrivateNote &&
    (!assignedAgent.value || assignedAgent.value.id !== currentUser.value?.id)
);

const isAIOwned = computed(() =>
  isAIAssigneeType(currentChat.value?.meta?.assignee_type)
);
const showBotHandoffBanner = computed(
  () =>
    currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING &&
    isAIOwned.value
);

const botAssigneeName = computed(() => {
  if (isAIOwned.value && assignedAgent.value?.name) {
    return assignedAgent.value.name;
  }

  return t('CONVERSATION.BOT_HANDOFF_FALLBACK_ASSIGNEE');
});

const selfAssignConversation = async conversationId => {
  const { data } = await ConversationApi.assignAgent({
    conversationId,
    agentId: currentUser.value.id,
    assigneeType: 'User',
  });
  await store.dispatch('setCurrentChatAssignee', {
    conversationId,
    assignee: data,
    assigneeType: 'User',
  });
};

const onClickSelfAssign = async () => {
  try {
    await selfAssignConversation(currentChat.value.id);
    useAlert(t('CONVERSATION.CHANGE_AGENT'));
  } catch (error) {
    useAlert(t('CONVERSATION.CHANGE_AGENT_FAILED'));
  }
};

const onClickBotHandoff = async () => {
  const conversationId = currentChat.value.id;
  try {
    await selfAssignConversation(conversationId);
    store.commit('CHANGE_CONVERSATION_STATUS', {
      conversationId,
      status: 'open',
      snoozedUntil: null,
    });
    useAlert(t('CONVERSATION.BOT_HANDOFF_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.BOT_HANDOFF_ERROR'));
  }
};
</script>

<template>
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
    :banner-message="
      $t('CONVERSATION.BOT_HANDOFF_MESSAGE', {
        assigneeName: botAssigneeName,
      })
    "
    has-action-button
    :action-button-label="$t('CONVERSATION.BOT_HANDOFF_ACTION')"
    @primary-action="onClickBotHandoff"
  />
</template>
