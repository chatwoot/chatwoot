<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue';

const { t } = useI18n();
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
    class="flex items-center justify-center py-10 text-s-muted"
  >
    <Spinner />
  </div>
  <div
    v-else-if="contactConversations.length > 0"
    class="px-6 py-4 divide-y divide-s-border-strong [&>*:hover]:!border-y-transparent [&>*:hover+*]:!border-t-transparent"
  >
    <ConversationCard
      v-for="conversation in contactConversations"
      :key="conversation.id"
      :conversation="conversation"
      :contact="contactsById(conversation.meta.sender.id)"
      :state-inbox="stateInbox(conversation.inboxId)"
      :account-labels="accountLabelsValue"
      class="rounded-none hover:rounded-xl hover:bg-s-subtle dark:hover:bg-s-subtle"
    />
  </div>
  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-s-muted">
    {{ t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.EMPTY_STATE') }}
  </p>
</template>
