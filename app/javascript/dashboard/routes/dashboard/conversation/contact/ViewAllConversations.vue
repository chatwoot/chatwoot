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

// Scoping the list to one contact only says something when there is more than
// the conversation already open, and only where a conversation list exists to
// scope — the inbox view has none.
const isVisible = computed(() => {
  if (String(route.name || '').startsWith('inbox_view')) return false;
  return contactConversations.value(props.contact.id).length > 1;
});

// On the expanded layout the list sits behind the open conversation, so move to
// it first and let the filter land on a list the agent can see. The path keeps
// the current inbox or team, which stops the list from resetting the filter.
const viewAllConversations = async () => {
  if (isOnExpandedLayout.value) {
    await router.push(buildConversationListPath());
  }

  store.dispatch('applyConversationFilters', [
    {
      attribute_key: 'contact_id',
      attribute_model: 'standard',
      filter_operator: 'equal_to',
      query_operator: 'and',
      custom_attribute_type: '',
      values: [{ id: props.contact.id, name: props.contact.name }],
    },
  ]);
};
</script>

<template>
  <NextButton
    v-if="isVisible"
    :label="$t('CONTACT_PANEL.CONVERSATIONS.VIEW_ALL')"
    class="w-full"
    icon="i-lucide-messages-square"
    justify="center"
    outline
    slate
    sm
    @click="viewAllConversations"
  />
</template>
