<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue';

const route = useRoute();

const conversations = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);
const contactsById = useMapGetter('contacts/getContactById');
const stateInbox = useMapGetter('inboxes/getInboxById');
const accountLabels = useMapGetter('labels/getLabels');

const accountLabelsValue = computed(() => accountLabels.value);

const uiFlags = useMapGetter('contactConversations/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);

const contactConversations = computed(() =>
  conversations.value(route.params.contactId)
);
</script>

<template>
  <div
    v-if="isFetching"
    class="flex items-center justify-center py-10 text-n-slate-11"
  >
    <Spinner />
  </div>
  <div v-else class="flex flex-col py-6">
    <div
      v-for="conversation in contactConversations"
      :key="conversation.id"
      class="px-3 border-b border-n-strong"
    >
      <ConversationCard
        v-if="conversation"
        :key="conversation.id"
        :conversation="conversation"
        :contact="contactsById(conversation.meta.sender.id)"
        :state-inbox="stateInbox(conversation.inboxId)"
        :account-labels="accountLabelsValue"
      />
    </div>
  </div>
</template>
