<script setup>
import { computed } from 'vue';
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
        tab =>
          typeof tab.label === 'string' &&
          (tab.count ? typeof tab.count === 'number' : true)
      );
    },
  },
});

const emit = defineEmits(['tabChanged']);

const activeTab = computed(() => props.initialActiveTab);

const selectTab = index => {
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
  <div class="flex items-center h-8 rounded-lg bg-n-alpha-1 w-fit">
    <template v-for="(tab, index) in tabs" :key="index">
      <button
        class="relative px-4 truncate py-1.5 text-sm border-0 outline-1 outline rounded-lg transition-colors duration-300 ease-in-out hover:text-n-brand"
        :class="[
          activeTab === index
            ? 'text-n-blue-text bg-n-solid-active outline-n-container dark:outline-transparent'
            : 'text-n-slate-10 outline-transparent h-8',
        ]"
        @click="selectTab(index)"
      >
        {{ tab.label }} {{ tab.count ? `(${tab.count})` : '' }}
      </button>
      <div
        class="w-px h-3.5 rounded my-auto transition-colors duration-300 ease-in-out"
        :class="
          showDivider(index)
            ? 'bg-n-strong'
            : 'bg-transparent dark:bg-transparent'
        "
      />
    </template>
  </div>
</template>
