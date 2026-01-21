<script setup>
import { computed, ref, onMounted, nextTick, watch } from 'vue';
import { useResizeObserver } from '@vueuse/core';

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

const tabRefs = ref([]);
const indicatorStyle = ref({});
const enableTransition = ref(false);

const activeElement = computed(() => tabRefs.value[activeTab.value]);

const updateIndicator = () => {
  nextTick(() => {
    if (!activeElement.value) return;

    indicatorStyle.value = {
      left: `${activeElement.value.offsetLeft}px`,
      width: `${activeElement.value.offsetWidth}px`,
    };
  });
};

useResizeObserver(activeElement, updateIndicator);

// Watch for prop/tabs changes to update indicator position
watch([() => props.initialActiveTab, () => props.tabs], updateIndicator, {
  immediate: true,
});

onMounted(() => {
  nextTick(() => {
    enableTransition.value = true;
  });
});

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
  <div
    class="relative flex items-center h-8 rounded-lg bg-n-alpha-1 dark:bg-n-solid-1 w-fit transition-all duration-200 ease-out has-[button:active]:scale-[1.01]"
  >
    <div
      class="absolute rounded-lg bg-n-solid-active shadow-sm pointer-events-none h-8 outline-1 outline outline-n-container inset-y-0"
      :class="{ 'transition-all duration-300 ease-out': enableTransition }"
      :style="indicatorStyle"
    />

    <template v-for="(tab, index) in tabs" :key="index">
      <button
        :ref="el => (tabRefs[index] = el)"
        class="relative z-10 px-4 truncate py-1.5 text-sm border-0 outline-1 outline-transparent rounded-lg transition-all duration-200 ease-out hover:text-n-brand active:scale-[1.02]"
        :class="[
          activeTab === index
            ? 'text-n-blue-text scale-100'
            : 'text-n-slate-10 scale-[0.98]',
        ]"
        @click="selectTab(index)"
      >
        {{ tab.label }} {{ tab.count ? `(${tab.count})` : '' }}
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
