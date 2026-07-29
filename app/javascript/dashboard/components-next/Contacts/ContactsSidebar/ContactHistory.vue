<script setup>
import { computed, ref, watch } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { toConversationSortParam } from 'dashboard/helper/conversationSortOptions';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactConversationsTable from './ContactConversationsTable.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

const conversations = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);
const uiFlags = useMapGetter('contactConversations/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);

const sortState = ref({
  activeSort: 'last_activity_at',
  activeOrdering: '-',
});

const contactConversations = computed(() =>
  conversations.value(route.params.contactId)
);

const fetchConversations = (contactId = route.params.contactId) => {
  if (!contactId) return;
  const sortBy = toConversationSortParam(
    sortState.value.activeSort,
    sortState.value.activeOrdering
  );
  store.dispatch('contactConversations/get', { contactId, sortBy });
};

const handleSort = ({ sort, order }) => {
  sortState.value = { activeSort: sort, activeOrdering: order };
  fetchConversations();
};

watch(
  () => route.params.contactId,
  contactId => {
    if (contactId) fetchConversations(contactId);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-8 text-n-slate-11"
    >
      <Spinner />
    </div>
    <ContactConversationsTable
      v-else-if="contactConversations.length > 0"
      :conversations="contactConversations"
      :active-sort="sortState.activeSort"
      :active-ordering="sortState.activeOrdering"
      @update:sort="handleSort"
    />
    <p v-else class="px-4 py-8 text-sm leading-6 text-center text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.EMPTY_STATE') }}
    </p>
  </div>
</template>
