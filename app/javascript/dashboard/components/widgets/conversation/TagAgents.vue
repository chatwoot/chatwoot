<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';

const props = defineProps({
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectAgent']);

const getters = useStoreGetters();
const agents = computed(() => getters['agents/getVerifiedAgents'].value);

const tagAgentsRef = ref(null);
const selectedIndex = ref(0);

const items = computed(() => {
  if (!props.searchKey) {
    return agents.value;
  }
  return agents.value.filter(agent =>
    agent.name.toLowerCase().includes(props.searchKey.toLowerCase())
  );
});

const adjustScroll = () => {
  nextTick(() => {
    if (tagAgentsRef.value) {
      tagAgentsRef.value.scrollTop = 50 * selectedIndex.value;
    }
  });
};

const onSelect = () => {
  emit('selectAgent', items.value[selectedIndex.value]);
};

useKeyboardNavigableList({
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(items, newListOfAgents => {
  if (newListOfAgents.length < selectedIndex.value + 1) {
    selectedIndex.value = 0;
  }
});

const onHover = index => {
  selectedIndex.value = index;
};

const onAgentSelect = index => {
  selectedIndex.value = index;
  onSelect();
};
</script>

<template>
  <div>
    <ul
      v-if="items.length"
      ref="tagAgentsRef"
      class="vertical dropdown menu mention--box bg-white text-sm dark:bg-slate-700 rounded-md overflow-auto absolute w-full z-20 pt-2 px-2 pb-0 shadow-md left-0 leading-[1.2] bottom-full max-h-[12.5rem] border-t border-solid border-slate-75 dark:border-slate-800"
      :class="{
        'border-b-[0.5rem] border-solid border-white dark:!border-slate-700':
          items.length <= 4,
      }"
    >
      <li
        v-for="(agent, index) in items"
        :id="`mention-item-${index}`"
        :key="agent.id"
        :class="{
          'bg-slate-50 dark:bg-slate-800': index === selectedIndex,
          'last:mb-0': items.length <= 4,
        }"
        class="flex items-center p-2 rounded-md last:mb-2"
        @click="onAgentSelect(index)"
        @mouseover="onHover(index)"
      >
        <div class="mr-2">
          <woot-thumbnail
            :src="agent.thumbnail"
            :username="agent.name"
            size="32px"
          />
        </div>
        <div
          class="flex-1 max-w-full overflow-hidden whitespace-nowrap text-ellipsis"
        >
          <h5
            class="mb-0 overflow-hidden text-sm text-slate-800 dark:text-slate-100 whitespace-nowrap text-ellipsis"
            :class="{
              'text-slate-900 dark:text-slate-100': index === selectedIndex,
            }"
          >
            {{ agent.name }}
          </h5>
          <div
            class="overflow-hidden text-xs whitespace-nowrap text-ellipsis text-slate-700 dark:text-slate-300"
            :class="{
              'text-slate-800 dark:text-slate-200': index === selectedIndex,
            }"
          >
            {{ agent.email }}
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
