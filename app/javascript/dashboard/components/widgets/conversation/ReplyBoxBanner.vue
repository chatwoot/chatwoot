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
    const agentId = agent ? agent.id : 0;
    store.dispatch('setCurrentChatAssignee', agent);
    store.dispatch('assignAgent', {
      conversationId: currentChat.value?.id,
      agentId,
    });
  },
});

const showSelfAssignBanner = computed(() => {
  if (props.message !== '' && !props.isOnPrivateNote) {
    if (!assignedAgent.value) {
      return true;
    }
    if (assignedAgent.value?.id !== currentUser.value?.id) {
      return true;
    }
  }
  return false;
});

const showBotHandoffBanner = computed(() => {
  return (
    props.message !== '' &&
    !props.isOnPrivateNote &&
    currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING
  );
});

const botHandoffActionLabel = computed(() => {
  return assignedAgent.value?.id === currentUser.value?.id
    ? t('CONVERSATION.BOT_HANDOFF_REOPEN_ACTION')
    : t('CONVERSATION.BOT_HANDOFF_ACTION');
});

const selfAssignConversation = () => {
  const { avatar_url, ...rest } = currentUser.value;
  assignedAgent.value = { ...rest, thumbnail: avatar_url };
};

const onClickSelfAssign = async () => {
  try {
    await selfAssignConversation();
    useAlert(t('CONVERSATION.CHANGE_AGENT'));
  } catch (error) {
    useAlert(t('CONVERSATION.CHANGE_AGENT_FAILED'));
  }
};

const onClickBotHandoff = async () => {
  try {
    await store.dispatch('toggleStatus', {
      conversationId: currentChat.value?.id,
      status: wootConstants.STATUS_TYPE.OPEN,
    });
    // Only assign to self if not already assigned to current user
    if (
      !assignedAgent.value ||
      assignedAgent.value?.id !== currentUser.value?.id
    ) {
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
