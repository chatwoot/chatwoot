<script setup>
import { computed, ref } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';

import { usePolicy } from 'dashboard/composables/usePolicy';
import { useSidebarContext } from './provider';
import { useEventListener } from '@vueuse/core';

const props = defineProps({
  isExpanded: { type: Boolean, default: false },
  name: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
});

const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();
const { checkFeatureAllowed, checkPermissions } = usePolicy();
const scrollableContainer = ref(null);

const hasAccessibleItems = computed(() => {
  if (props.children.length === 0) {
    // cases like segment, folder and labels where users can create new items
    return true;
  }

  return props.children.some(child => {
    const permissions = resolvePermissions(child.to);
    const featureFlag = resolveFeatureFlag(child.to);

    return checkPermissions(permissions) && checkFeatureAllowed(featureFlag);
  });
});

const isScrollable = computed(() => {
  return props.children.length > 7;
});
const scrollEnd = ref(false);

// set scrollEnd to true when the scroll reaches the end
useEventListener(scrollableContainer, 'scroll', () => {
  const { scrollHeight, scrollTop, clientHeight } = scrollableContainer.value;
  scrollEnd.value = scrollHeight - scrollTop === clientHeight;
});
</script>

<template>
  <SidebarGroupSeparator
    v-if="hasAccessibleItems"
    v-show="isExpanded"
    :name
    :icon
    class="my-1"
  />
  <ul class="m-0 list-none relative">
    <!-- Each element has h-8, which is 32px, we will show 7 items with one hidden at the end,
    which is 14rem. Then we add 16px so that we have some text visible from the next item  -->
    <div
      ref="scrollableContainer"
      :class="{
        'max-h-[calc(14rem+16px)] overflow-y-scroll no-scrollbar': isScrollable,
      }"
    >
      <template v-if="children.length">
        <SidebarGroupLeaf
          v-for="child in children"
          v-show="isExpanded || activeChild?.name === child.name"
          v-bind="child"
          :key="child.name"
          :active="activeChild?.name === child.name"
        />
      </template>
      <SidebarGroupEmptyLeaf v-else v-show="isExpanded" />
    </div>
    <div
      v-if="isScrollable && isExpanded"
      v-show="!scrollEnd"
      class="absolute bg-gradient-to-t from-n-solid-2 w-full h-12 to-transparent -bottom-1 pointer-events-none flex items-end justify-end px-3"
    >
      <svg
        width="16"
        height="24"
        viewBox="0 0 16 24"
        fill="none"
        class="text-n-slate-9"
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
