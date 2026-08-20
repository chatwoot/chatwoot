<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useConversationRoutePath } from 'dashboard/composables/useConversationRoutePath';
import { useUISettings } from 'dashboard/composables/useUISettings';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

// On the expanded layout the list sits behind the open conversation, so move
// to it first; the path keeps the current inbox/team scope so the list does
// not reset the filter on navigation.
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
  <button
    v-if="isVisible"
    class="flex items-center justify-between w-full px-4 py-2 mb-3 rounded-lg select-none outline outline-1 outline-n-weak bg-n-slate-2 transition-colors hover:bg-n-slate-3"
    @click="viewAllConversations"
  >
    <span class="text-sm text-n-slate-12">
      {{ $t('CONTACT_PANEL.CONVERSATIONS.VIEW_ALL') }}
    </span>
    <Icon
      icon="i-lucide-chevron-right"
      class="size-4 text-n-blue-11 rtl:rotate-180"
    />
  </button>
</template>
