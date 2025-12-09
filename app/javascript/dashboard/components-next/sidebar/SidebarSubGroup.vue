<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import Icon from 'next/icon/Icon.vue';

import { useSidebarContext } from './provider';
import { useEventListener } from '@vueuse/core';

const props = defineProps({
  name: { type: String, required: true },
  parentExpanded: { type: Boolean, default: false },
  label: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
});

const { isAllowed, isItemExpanded, setExpandedItem } = useSidebarContext();
const scrollableContainer = ref(null);

const isExpanded = computed(() => isItemExpanded(props.name));
const hasActiveChild = computed(() => props.activeChild !== undefined);
const showChildren = computed(() => props.parentExpanded && isExpanded.value);

const toggleExpanded = () => {
  setExpandedItem(props.name);
};

// Auto-expand when there's an active child
onMounted(() => {
  if (hasActiveChild.value && !isExpanded.value) {
    setExpandedItem(props.name);
  }
});

// Watch for active child changes and auto-expand (only when transitioning from no active child to having one)
watch(
  () => props.activeChild,
  (newActiveChild, oldActiveChild) => {
    if (newActiveChild && !oldActiveChild && !isExpanded.value) {
      setExpandedItem(props.name);
    }
  }
);

const accessibleItems = computed(() =>
  props.children.filter(child => {
    return child.to && isAllowed(child.to);
  })
);

const hasAccessibleItems = computed(() => {
  return accessibleItems.value.length > 0;
});

const isScrollable = computed(() => {
  return accessibleItems.value.length > 7;
});

const scrollEnd = ref(false);

// set scrollEnd to true when the scroll reaches the end
useEventListener(scrollableContainer, 'scroll', () => {
  const { scrollHeight, scrollTop, clientHeight } = scrollableContainer.value;
  scrollEnd.value = scrollHeight - scrollTop === clientHeight;
});
</script>

<template>
  <div v-if="hasAccessibleItems && parentExpanded" class="my-1">
    <div
      class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-8 min-w-0 cursor-pointer select-none text-n-slate-11 hover:bg-n-alpha-2"
      role="button"
      @click="toggleExpanded"
    >
      <div v-if="icon" class="flex items-center gap-2">
        <Icon v-if="icon" :icon="icon" class="size-4" />
      </div>
      <div class="flex items-center gap-1.5 flex-grow min-w-0">
        <span class="text-sm font-medium leading-5 truncate">
          {{ label }}
        </span>
      </div>
      <span
        class="i-lucide-chevron-up size-3 transition-transform duration-200"
        :class="{ 'rotate-180': !isExpanded }"
        :title="isExpanded ? 'Recolher' : 'Expandir'"
      />
    </div>
  </div>
  <ul
    v-if="children.length && showChildren"
    class="m-0 list-none reset-base relative group"
  >
    <!-- Each element has h-8, which is 32px, we will show 7 items with one hidden at the end,
    which is 14rem. Then we add 16px so that we have some text visible from the next item  -->
    <div
      ref="scrollableContainer"
      :class="{
        'max-h-[calc(14rem+16px)] overflow-y-scroll no-scrollbar': isScrollable,
      }"
    >
      <SidebarGroupLeaf
        v-for="child in children"
        v-show="showChildren"
        v-bind="child"
        :key="child.name"
        :active="activeChild?.name === child.name"
      />
    </div>
    <div
      v-if="isScrollable && showChildren"
      v-show="!scrollEnd"
      class="absolute bg-gradient-to-t from-n-solid-2 w-full h-12 to-transparent -bottom-1 pointer-events-none flex items-end justify-end px-2 animate-fade-in-up"
    >
      <svg
        width="16"
        height="24"
        viewBox="0 0 16 24"
        fill="none"
        class="text-n-slate-9 opacity-50 group-hover:opacity-100"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M4 4L8 8L12 4"
          stroke="currentColor"
          opacity="0.5"
          stroke-width="1.33333"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M4 10L8 14L12 10"
          stroke="currentColor"
          opacity="0.75"
          stroke-width="1.33333"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M4 16L8 20L12 16"
          stroke="currentColor"
          stroke-width="1.33333"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </div>
  </ul>
</template>
