<script setup>
import { ref } from 'vue';
const props = defineProps({
  initialActiveTab: {
    type: Number,
    default: 0,
  },
  tabs: {
    type: Array,
    required: true,
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
const showDivider = index => {
  return (
    // Show dividers after the active tab, but not after the last tab
    (index > activeTab.value && index < props.tabs.length - 1) ||
    // Show dividers before the active tab, but not immediately before it and not before the first tab
    (index < activeTab.value - 1 && index > -1)
  );
};
</script>

<template>
  <div class="flex h-8 rounded-lg bg-slate-25 dark:bg-slate-800/50 w-fit">
    <template v-for="(tab, index) in tabs" :key="index">
      <button
        class="relative px-4 truncate py-1.5 text-sm border-0 rounded-lg transition-colors duration-300 ease-in-out"
        :class="[
          activeTab === index
            ? 'text-woot-500 bg-woot-500/10 dark:bg-woot-500/10'
            : 'text-slate-500 dark:text-slate-400 hover:text-woot-500 dark:hover:text-woot-400',
        ]"
        @click="selectTab(index)"
      >
        {{ tab.label }} {{ tab.count ? `(${tab.count})` : '' }}
      </button>
      <div
        class="w-px h-3.5 rounded my-auto transition-colors duration-300 ease-in-out"
        :class="
          showDivider(index)
            ? 'bg-slate-75 dark:bg-slate-800'
            : 'bg-transparent dark:bg-transparent'
        "
      />
    </template>
  </div>
</template>
