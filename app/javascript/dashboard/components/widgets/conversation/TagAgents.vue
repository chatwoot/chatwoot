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

  let filteredAgents = agentItems;
  let filteredTeams = teamItems;

  if (props.searchKey) {
    filteredAgents = agentItems.filter(agent =>
      agent.displayName.toLowerCase().includes(props.searchKey.toLowerCase())
    );
    filteredTeams = teamItems.filter(team =>
      team.displayName.toLowerCase().includes(props.searchKey.toLowerCase())
    );
  }

  const result = [];

  if (filteredAgents.length > 0) {
    result.push({ type: 'header', title: 'Agents', id: 'agents-header' });
    result.push(...filteredAgents);
  }

  if (filteredTeams.length > 0) {
    result.push({ type: 'header', title: 'Teams', id: 'teams-header' });
    result.push(...filteredTeams);
  }

  return result;
});

const selectableItems = computed(() => {
  return items.value.filter(item => item.type !== 'header');
});

const getSelectableIndex = item => {
  return selectableItems.value.findIndex(
    selectableItem =>
      selectableItem.type === item.type && selectableItem.id === item.id
  );
};

const adjustScroll = () => {
  nextTick(() => {
    if (tagAgentsRef.value) {
      const selectedElement = tagAgentsRef.value.querySelector(
        `#mention-item-${selectedIndex.value}`
      );
      if (selectedElement) {
        selectedElement.scrollIntoView({
          block: 'nearest',
          behavior: 'smooth',
        });
      }
    }
  });
};

const onSelect = () => {
  emit('selectAgent', selectableItems.value[selectedIndex.value]);
};

useKeyboardNavigableList({
  items: selectableItems,
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(selectableItems, newListOfAgents => {
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
    <div
      v-if="items.length"
      ref="tagAgentsRef"
      class="vertical dropdown menu mention--box bg-n-solid-1 p-1 rounded-xl text-sm overflow-auto absolute w-full z-20 shadow-md left-0 leading-[1.2] bottom-full max-h-[12.5rem] border border-solid border-n-strong"
    >
      <div
        v-for="item in items"
        :id="
          item.type === 'header'
            ? undefined
            : `mention-item-${getSelectableIndex(item)}`
        "
        :key="`${item.type}-${item.id}`"
      >
        <!-- Section Header -->
        <div
          v-if="item.type === 'header'"
          class="px-2 py-2 text-xs font-medium tracking-wide capitalize text-n-slate-11"
        >
          {{ item.title }}
        </div>
        <!-- Selectable Item -->
        <div
          v-else
          :class="{
            'bg-n-alpha-black2': getSelectableIndex(item) === selectedIndex,
          }"
          class="flex items-center px-2 py-1 rounded-md cursor-pointer"
          @click="onAgentSelect(getSelectableIndex(item))"
          @mouseover="onHover(getSelectableIndex(item))"
        >
          <div class="mr-2">
            <Avatar
              :src="item.thumbnail"
              :name="item.displayName"
              rounded-full
            />
          </div>
          <div
            class="overflow-hidden flex-1 max-w-full whitespace-nowrap text-ellipsis"
          >
            <h5
              class="overflow-hidden mb-0 text-sm capitalize whitespace-nowrap text-n-slate-11 text-ellipsis"
              :class="{
                'text-n-slate-12': getSelectableIndex(item) === selectedIndex,
              }"
            >
              {{ item.displayName }}
            </h5>
            <div
              class="overflow-hidden text-xs whitespace-nowrap text-ellipsis text-n-slate-10"
              :class="{
                'text-n-slate-11': getSelectableIndex(item) === selectedIndex,
              }"
            >
              {{ item.displayInfo }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
