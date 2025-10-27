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
  <div class="relative flex items-center h-8 rounded-lg bg-n-alpha-1 w-fit">
    <template v-for="(tab, index) in tabs" :key="index">
      <button
        class="relative px-4 truncate py-1.5 text-sm border-0 outline-1 outline-transparent rounded-[6px] transition-all duration-300 ease-out hover:text-n-brand active:scale-95 active:duration-75 before:absolute before:inset-0 before:m-0.5 before:rounded-[6px] before:bg-n-solid-active before:shadow-sm before:transition-all before:duration-300 before:ease-out before:scale-0 before:opacity-0"
        :class="[
          activeTab === index
            ? 'text-n-blue-text scale-100 before:scale-100 before:opacity-100'
            : 'text-n-slate-10 h-8 scale-[0.98] hover:scale-100',
        ]"
        @click="selectTab(index)"
      >
        <span class="relative z-10">
          {{ tab.label }} {{ tab.count ? `(${tab.count})` : '' }}
        </span>
      </button>
      <div
        v-if="index < tabs.length - 1"
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
