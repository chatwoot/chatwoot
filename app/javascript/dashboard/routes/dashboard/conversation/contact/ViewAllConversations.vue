<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useConversationRoutePath } from 'dashboard/composables/useConversationRoutePath';
import { useUISettings } from 'dashboard/composables/useUISettings';
import wootConstants from 'dashboard/constants/globals';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const route = useRoute();
const router = useRouter();
const { buildConversationListPath } = useConversationRoutePath();
const { isOnExpandedLayout } = useUISettings();

const contactConversations = useMapGetter(
  'contactConversations/getContactConversation'
);

// Needs more than the open conversation, and a list to scope — the inbox view has none.
const isVisible = computed(() => {
  if (String(route.name || '').startsWith('inbox_view')) return false;
  return contactConversations.value(props.contact.id).length > 1;
});

// Applying a filter empties the store; refetch the open conversation if it was dropped.
const restoreOpenConversation = () => {
  const conversationId = Number(route.params.conversation_id);
  if (!conversationId) return;
  if (!store.getters.getConversationById(conversationId)) {
    store.dispatch('getConversation', conversationId);
  }
};

// On the expanded layout, move to the list first; the path keeps the current scope.
const viewAllConversations = async () => {
  if (isOnExpandedLayout.value) {
    await router.push(buildConversationListPath());
  }

  store
    .dispatch('applyConversationFilters', {
      filters: [
        {
          attribute_key: 'contact_id',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          query_operator: 'and',
          custom_attribute_type: '',
          values: [{ id: props.contact.id, name: props.contact.name }],
        },
      ],
      // Match the chronological order of the in-thread navigation.
      sortBy: wootConstants.SORT_BY_TYPE.CREATED_AT_DESC,
    })
    .finally(restoreOpenConversation);
};
</script>

<template>
  <NextButton
    v-if="isVisible"
    v-tooltip.top-end="$t('CONTACT_PANEL.CONVERSATIONS.VIEW_ALL')"
    :aria-label="$t('CONTACT_PANEL.CONVERSATIONS.VIEW_ALL')"
    icon="i-lucide-history"
    slate
    faded
    sm
    @click="viewAllConversations"
  />
</template>
