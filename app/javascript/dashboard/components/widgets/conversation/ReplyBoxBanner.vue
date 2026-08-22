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

    store.dispatch('setCurrentChatAssignee', {

      conversationId: currentChat.value?.id,

      assignee: agent,

      assigneeType: agent ? 'User' : null,

    });

    store.dispatch('assignAgent', {

      conversationId: currentChat.value?.id,

      agentId,

    });

  },

});



const isAssignedToCurrentUser = computed(() => {

  if (!assignedAgent.value?.id || !currentUser.value?.id) return false;

  if (currentChat.value?.meta?.assignee_type === 'AgentBot') return false;

  return assignedAgent.value.id === currentUser.value.id;

});



const isPendingConversation = computed(

  () => currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING

);



const isAgentBotOwned = computed(

  () => currentChat.value?.meta?.assignee_type === 'AgentBot'

);



const showBotHandoffBanner = computed(() => {

  return (

    props.message !== '' &&

    !props.isOnPrivateNote &&

    isPendingConversation.value &&

    isAgentBotOwned.value

  );

});



const botAssigneeName = computed(() => {

  if (isAgentBotOwned.value && assignedAgent.value?.name) {

    return assignedAgent.value.name;

  }



  return t('CONVERSATION.BOT_HANDOFF_FALLBACK_ASSIGNEE');

});



const botHandoffActionLabel = computed(() =>

  isAssignedToCurrentUser.value

    ? t('CONVERSATION.BOT_HANDOFF_REOPEN_ACTION')

    : t('CONVERSATION.BOT_HANDOFF_ACTION')

);



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

    status: 'open',

  });

};



const onClickBotHandoff = async () => {

  try {

    const shouldAssignToCurrentUser =

      isAgentBotOwned.value || needsAssignmentToCurrentUser.value;



    await reopenConversation();



    if (shouldAssignToCurrentUser) {

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

    :banner-message="

      $t('CONVERSATION.BOT_HANDOFF_MESSAGE', {

        assigneeName: botAssigneeName,

      })

    "

    has-action-button

    :action-button-label="botHandoffActionLabel"

    @primary-action="onClickBotHandoff"

  />

</template>


