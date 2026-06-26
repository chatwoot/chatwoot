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

const isAssignedToCurrentUser = computed(() => {
  const assignee = currentChat.value?.meta?.assignee;
  const assigneeType = currentChat.value?.meta?.assignee_type;
  if (!assignee?.id || !currentUser.value?.id) return false;
  if (assigneeType === 'AgentBot') return false;
  return assignee.id === currentUser.value.id;
});

const showBotHandoffBanner = computed(
  () =>
    props.message !== '' &&
    !props.isOnPrivateNote &&
    currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING
);

const botHandoffActionLabel = computed(() => {
  return isAssignedToCurrentUser.value
    ? t('CONVERSATION.BOT_HANDOFF_REOPEN_ACTION')
    : t('CONVERSATION.BOT_HANDOFF_ACTION');
});

const selfAssignConversation = async () => {
  const conversationId = currentChat.value?.id;
  const previousAssignee = currentChat.value?.meta?.assignee;
  const previousAssigneeType = currentChat.value?.meta?.assignee_type;
  const { avatar_url, ...rest } = currentUser.value || {};
  const nextAssignee = { ...rest, thumbnail: avatar_url };

  store.dispatch('setCurrentChatAssignee', {
    conversationId,
    assignee: nextAssignee,
    assigneeType: 'User',
  });

  try {
    await store.dispatch('assignAgent', {
      conversationId,
      agentId: currentUser.value?.id,
      assigneeType: 'User',
    });
  } catch (error) {
    store.dispatch('setCurrentChatAssignee', {
      conversationId,
      assignee: previousAssignee,
      assigneeType: previousAssigneeType,
    });
    throw error;
  }
};

const needsAssignmentToCurrentUser = computed(
  () => !isAssignedToCurrentUser.value
);

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
</script>

<template>
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
