<script setup>
import Avatar from 'next/avatar/Avatar.vue';
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
const teams = computed(() => getters['teams/getTeams'].value);

const tagAgentsRef = ref(null);
const selectedIndex = ref(0);

const items = computed(() => {
  const agentItems = agents.value.map(agent => ({
    ...agent,
    type: 'user',
    displayName: agent.name,
    displayInfo: agent.email,
  }));

  const teamItems = teams.value.map(team => ({
    ...team,
    type: 'team',
    displayName: team.name,
    displayInfo: team.description,
  }));

  const allItems = [...agentItems, ...teamItems];

  if (!props.searchKey) return allItems;

  return allItems.filter(item =>
    item.displayName.toLowerCase().includes(props.searchKey.toLowerCase())
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
      class="vertical dropdown menu mention--box bg-n-solid-1 p-1 rounded-xl text-sm overflow-auto absolute w-full z-20 shadow-md left-0 leading-[1.2] bottom-full max-h-[12.5rem] border border-solid border-n-strong"
    >
      <li
        v-for="(item, index) in items"
        :id="`mention-item-${index}`"
        :key="`${item.type}-${item.id}`"
        :class="{
          'bg-n-alpha-black2': index === selectedIndex,
          'last:mb-0': items.length <= 4,
        }"
        class="flex items-center px-2 py-1 rounded-md"
        @click="onAgentSelect(index)"
        @mouseover="onHover(index)"
      >
        <div class="mr-2">
          <Avatar :src="item.thumbnail" :name="item.displayName" rounded-full />
        </div>
        <div
          class="flex-1 max-w-full overflow-hidden whitespace-nowrap text-ellipsis"
        >
          <h5
            class="mb-0 overflow-hidden text-sm capitalize text-n-slate-11 whitespace-nowrap text-ellipsis"
            :class="{
              'text-n-slate-12': index === selectedIndex,
            }"
          >
            {{ item.displayName }}
          </h5>
          <div
            class="overflow-hidden text-xs whitespace-nowrap text-ellipsis text-n-slate-10"
            :class="{
              'text-n-slate-11': index === selectedIndex,
            }"
          >
            {{ item.displayInfo }}
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
