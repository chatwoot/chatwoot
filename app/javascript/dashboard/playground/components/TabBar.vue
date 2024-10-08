<script setup>
import { ref } from 'vue';

const props = defineProps({
  initialActiveTab: {
    type: Number,
    default: 0,
  },
  tabs: {
    type: Array,
    default: () => [
      { label: 'All articles', count: 24 },
      { label: 'Mine', count: 13 },
      { label: 'Draft', count: 5 },
      { label: 'Archived', count: 11 },
    ],
    validator: value => {
      return value.every(
        tab => typeof tab.label === 'string' && typeof tab.count === 'number'
      );
    },
  },
});

const emit = defineEmits(['tabChanged']);

const activeTab = ref(props.initialActiveTab);

const selectTab = index => {
  activeTab.value = index;
  emit('tabChanged', props.tabs[index]);
};
</script>

<template>
  <div class="flex h-8 rounded-lg bg-slate-25 dark:bg-slate-800/50 w-fit">
    <button
      v-for="(tab, index) in tabs"
      :key="index"
      class="relative px-4 py-1.5 text-sm border-0 rounded-lg transition-colors duration-300 ease-in-out"
      :class="[
        activeTab === index
          ? 'text-woot-500 bg-slate-50 dark:bg-slate-800'
          : 'text-slate-500 dark:text-slate-400 hover:text-woot-500 dark:hover:text-woot-400',
      ]"
      @click="selectTab(index)"
    >
      {{ tab.label }} {{ tab.count ? `(${tab.count})` : '' }}
    </button>
  </div>
</template>
