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
    class="relative flex h-8 w-fit items-center rounded-lg bg-surface-container-low/90 ring-1 ring-inset ring-outline-variant/15 transition-all duration-200 ease-out has-[button:active]:scale-[1.01]"
  >
    <div
      class="pointer-events-none absolute inset-y-0 rounded-lg bg-surface-container-highest shadow-sm ring-1 ring-outline-variant/25"
      :class="{ 'transition-all duration-300 ease-out': enableTransition }"
      :style="indicatorStyle"
    />

    <template v-for="(tab, index) in tabs" :key="index">
      <button
        :ref="el => (tabRefs[index] = el)"
        class="relative z-10 truncate rounded-lg border-0 px-4 py-1.5 text-sm font-medium outline outline-1 outline-transparent transition-all duration-200 ease-out active:scale-[1.02] hover:text-on-surface"
        :class="[
          activeTab === index
            ? 'scale-100 text-on-surface'
            : 'scale-[0.98] text-on-surface-variant',
        ]"
        type="button"
        @click="selectTab(index)"
      >
        {{ tab.label }} {{ tab.count ? `(${tab.count})` : '' }}
      </button>
      <div
        v-if="index < tabs.length - 1"
        class="my-auto h-3.5 w-px rounded transition-colors duration-300 ease-in-out"
        :class="showDivider(index) ? 'bg-outline-variant/35' : 'bg-transparent'"
      />
    </template>
  </div>
</template>
