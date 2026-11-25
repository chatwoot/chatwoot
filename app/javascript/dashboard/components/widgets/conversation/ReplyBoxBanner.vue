<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert, useAssignmentError } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { isAIAssigneeType } from 'dashboard/helper/agentHelper';
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

// The store action owns the optimistic write and its rollback, and a rejected
// claim (an inbox with `prevent_assignment_takeover` answers 409) rolls back.
const selfAssignConversation = async conversationId => {
  const { avatar_url, ...rest } = currentUser.value || {};
  await store.dispatch('assignAgent', {
    conversationId,
    assignee: { ...rest, thumbnail: avatar_url },
    assigneeType: 'User',
  });
};

const showSelfAssignBanner = computed(
  () =>
    props.message !== '' &&
    !props.isOnPrivateNote &&
    (!assignedAgent.value || assignedAgent.value.id !== currentUser.value?.id)
);

const showBotHandoffBanner = computed(
  () =>
    currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING &&
    isAIAssigneeType(currentChat.value?.meta?.assignee_type)
);

const botAssigneeName = computed(
  () =>
    assignedAgent.value?.name || t('CONVERSATION.BOT_HANDOFF_FALLBACK_ASSIGNEE')
);

const onClickSelfAssign = async () => {
  try {
    await selfAssignConversation(currentChat.value.id);
    useAlert(t('CONVERSATION.CHANGE_AGENT'));
  } catch (error) {
    useAssignmentError(error, t('CONVERSATION.CHANGE_AGENT_FAILED'));
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
    useAssignmentError(error, t('CONVERSATION.BOT_HANDOFF_ERROR'));
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
