<script setup>
import { ref, computed, watch, nextTick } from 'vue';
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

const tagToolsRef = ref(null);
const selectedIndex = ref(0);

const filteredTools = computed(() => {
  const search = props.searchKey?.trim().toLowerCase() || '';

  return tools.value.filter(tool => tool.title.toLowerCase().includes(search));
});

const selectableItems = computed(() => {
  return filteredTools.value;
});

const getSelectableIndex = item => {
  return selectableItems.value.findIndex(
    selectableItem => selectableItem.id === item.id
  );
};

const adjustScroll = () => {
  nextTick(() => {
    if (tagToolsRef.value) {
      const selectedElement = tagToolsRef.value.querySelector(
        `#tool-item-${selectedIndex.value}`
      );
      if (selectedElement) {
        selectedElement.scrollIntoView({
          block: 'nearest',
          behavior: 'auto',
        });
      }
    }
  });
};

const onSelect = () => {
  emit('selectTool', selectableItems.value[selectedIndex.value]);
};

useKeyboardNavigableList({
  items: selectableItems,
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(selectableItems, newListOfTools => {
  if (newListOfTools.length < selectedIndex.value + 1) {
    selectedIndex.value = 0;
  }
});
</script>

<template>
  <div
    v-if="selectableItems.length"
    ref="tagToolsRef"
    class="w-[22.5rem] p-2 flex flex-col gap-1 z-50 absolute rounded-xl bg-n-alpha-3 shadow outline outline-1 outline-n-weak backdrop-blur-[50px] bottom-20 max-h-[20rem] overflow-y-auto"
  >
    <div
      v-for="tool in selectableItems"
      :id="`tool-item-${getSelectableIndex(tool)}`"
      :key="tool.id"
      :class="{
        'bg-n-alpha-black2': getSelectableIndex(tool) === selectedIndex,
      }"
      class="flex flex-col gap-1 rounded-md py-2 px-2 cursor-pointer hover:bg-n-alpha-black2"
      @click="onSelect(getSelectableIndex(tool))"
    >
      <span class="text-n-slate-12 font-medium text-sm">{{ tool.title }}</span>
      <span class="text-n-slate-11 text-sm">
        {{ tool.description }}
      </span>
    </div>
  </div>
  <template v-else />
</template>
