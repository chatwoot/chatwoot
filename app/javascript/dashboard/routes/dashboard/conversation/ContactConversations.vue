<script setup>
import { computed, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SidepanelEmptyState from 'dashboard/routes/dashboard/conversation/SidepanelEmptyState.vue';

const props = defineProps({
  contactId: {
    type: [String, Number],
    required: true,
  },
  conversationId: {
    type: [String, Number],
    required: true,
  },
});

const store = useStore();

const uiFlags = useMapGetter('contactConversations/getUIFlags');
const conversations = useMapGetter(
  'contactConversations/getContactConversation'
);

const previousConversations = computed(() => {
  return (
    conversations
      .value(props.contactId)
      ?.filter(
        conversation => conversation.id !== Number(props.conversationId)
      ) || []
  );
});

watch(
  () => props.contactId,
  (newContactId, prevContactId) => {
    if (newContactId && newContactId !== prevContactId) {
      store.dispatch('contactConversations/get', newContactId);
    }
  }
);

onMounted(() => {
  store.dispatch('contactConversations/get', props.contactId);
});
</script>

<template>
  <div v-if="!uiFlags.isFetching" class="max-h-96 overflow-y-auto px-3">
    <div v-if="!previousConversations.length" class="mt-2">
      <SidepanelEmptyState
        :message="$t('CONTACT_PANEL.CONVERSATIONS.NO_RECORDS_FOUND')"
      />
    </div>

    <div v-else>
      <ConversationCard
        v-for="conversation in previousConversations"
        :key="conversation.id"
        :chat="conversation"
        show-assignee
        hide-thumbnail
        enable-context-menu
        compact
        is-previous-conversations
        :allowed-context-menu-options="['open-new-tab', 'copy-link']"
      />
    </div>
  </div>
  <div v-else class="flex items-center justify-center py-5">
    <Spinner />
  </div>
</template>
