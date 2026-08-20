<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useConversationRoutePath } from 'dashboard/composables/useConversationRoutePath';
import { useUISettings } from 'dashboard/composables/useUISettings';
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

// Scoping needs more than the open conversation, and a conversation list to
// scope — the inbox view has none.
const isVisible = computed(() => {
  if (String(route.name || '').startsWith('inbox_view')) return false;
  return contactConversations.value(props.contact.id).length > 1;
});

// Applying a filter empties the conversation store, which drops the open
// conversation when it is not in the first filtered page or the fetch fails —
// fetch it back, as the filter modal path does through `conversationLoad`.
const restoreOpenConversation = () => {
  const conversationId = Number(route.params.conversation_id);
  if (!conversationId) return;
  if (!store.getters.getConversationById(conversationId)) {
    store.dispatch('getConversation', conversationId);
  }
};

// On the expanded layout the list sits behind the open conversation, so move
// to it first; the path keeps the current inbox/team scope so the list does
// not reset the filter on navigation.
const viewAllConversations = async () => {
  if (isOnExpandedLayout.value) {
    await router.push(buildConversationListPath());
  }

  store
    .dispatch('applyConversationFilters', [
      {
        attribute_key: 'contact_id',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        query_operator: 'and',
        custom_attribute_type: '',
        values: [{ id: props.contact.id, name: props.contact.name }],
      },
    ])
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
