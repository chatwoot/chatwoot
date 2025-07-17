<script setup>
import { ref, computed, watch } from 'vue';
import ToolsDropdown from 'dashboard/components-next/captain/assistant/ToolsDropdown.vue';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';

const props = defineProps({
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectTool']);

// TODO: Add tools
const tools = ref([
  {
    id: 'lookup_conversation',
    title: 'Lookup Conversation',
    description: 'Fetches current or past conversation threads by customer',
  },
  {
    id: 'fetch_customer',
    title: 'Fetch Customer',
    description: 'Pulls customer details (email, tags, last seen, etc.)',
  },
  {
    id: 'order_search',
    title: 'Order Search',
    description: 'Lookup orders by customer ID, email, or order number',
  },
  {
    id: 'refund_payment',
    title: 'refund_payment',
    description: 'Initiates a refund on a specific payment',
  },
]);

const selectedIndex = ref(0);

const filteredTools = computed(() => {
  const search = props.searchKey?.trim().toLowerCase() || '';

  return tools.value.filter(tool => tool.title.toLowerCase().includes(search));
});

const adjustScroll = () => {};

const onSelect = () => {
  emit('selectTool', filteredTools.value[selectedIndex.value]);
};

useKeyboardNavigableList({
  items: filteredTools,
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(filteredTools, newListOfTools => {
  if (newListOfTools.length < selectedIndex.value + 1) {
    selectedIndex.value = 0;
  }
});
</script>

<template>
  <ToolsDropdown
    v-if="filteredTools.length"
    :items="filteredTools"
    :selected-index="selectedIndex"
    class="bottom-20"
    @select="onSelect"
  />
  <template v-else />
</template>
