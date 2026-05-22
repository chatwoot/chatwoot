<script setup>
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';

import { useSidebarContext } from './provider';
import { useEventListener } from '@vueuse/core';

const props = defineProps({
  name: { type: String, required: true },
  isExpanded: { type: Boolean, default: false },
  label: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
  collapsible: { type: Boolean, default: false },
});

const { isAllowed } = useSidebarContext();
const scrollableContainer = ref(null);
const accountId = useMapGetter('getCurrentAccountId');

const minimizedSectionsKey = LOCAL_STORAGE_KEYS.SIDEBAR_MINIMIZED_SECTIONS;

const getMinimizedSections = () => {
  const minimizedSections = LocalStorage.get(minimizedSectionsKey);
  return minimizedSections &&
    typeof minimizedSections === 'object' &&
    !Array.isArray(minimizedSections)
    ? minimizedSections
    : {};
};

const minimizedSections = ref(getMinimizedSections());
const storageKey = computed(() =>
  accountId.value ? `${accountId.value}:${props.name}` : props.name
);
const isSubGroupExpanded = computed(
  () => !props.collapsible || !minimizedSections.value[storageKey.value]
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
  return (
    props.isExpanded &&
    isSubGroupExpanded.value &&
    accessibleItems.value.length > 7
  );
});

const scrollEnd = ref(false);

const toggleSubGroup = () => {
  if (!props.collapsible) return;

  const nextMinimizedSections = { ...getMinimizedSections() };
  if (isSubGroupExpanded.value) {
    nextMinimizedSections[storageKey.value] = true;
  } else {
    delete nextMinimizedSections[storageKey.value];
  }

  minimizedSections.value = nextMinimizedSections;
  LocalStorage.set(minimizedSectionsKey, nextMinimizedSections);
};

const shouldShowItem = child => {
  return (
    isSubGroupExpanded.value &&
    (props.isExpanded || props.activeChild?.name === child.name)
  );
};

// set scrollEnd to true when the scroll reaches the end
useEventListener(scrollableContainer, 'scroll', () => {
  const { scrollHeight, scrollTop, clientHeight } = scrollableContainer.value;
  scrollEnd.value = scrollHeight - scrollTop === clientHeight;
});

useEventListener(window, 'storage', event => {
  if (event.key === minimizedSectionsKey) {
    minimizedSections.value = getMinimizedSections();
  }
});
</script>

<template>
  <SidebarGroupSeparator
    v-if="hasAccessibleItems"
    v-show="isExpanded"
    :label
    :icon
    :collapsible
    :is-expanded="isSubGroupExpanded"
    class="my-1"
    @toggle="toggleSubGroup"
  />
  <ul
    v-if="children.length"
    class="m-0 list-none reset-base relative group min-w-0"
    :class="{
      'w-[calc(100%-1.25rem)] ltr:ml-5 rtl:mr-5': collapsible,
    }"
  >
    <!-- Each element has h-8, which is 32px, we will show 7 items with one hidden at the end,
    which is 14rem. Then we add 16px so that we have some text visible from the next item  -->
    <div
      ref="scrollableContainer"
      class="min-w-0"
      :class="{
        'max-h-[calc(14rem+16px)] overflow-y-scroll no-scrollbar': isScrollable,
      }"
    >
      <SidebarGroupLeaf
        v-for="child in children"
        v-show="shouldShowItem(child)"
        v-bind="child"
        :key="child.name"
        :active="activeChild?.name === child.name"
      />
    </div>
    <div
      v-if="isScrollable && isExpanded"
      v-show="!scrollEnd"
      class="absolute bg-gradient-to-t from-n-background w-full h-12 to-transparent -bottom-1 pointer-events-none flex items-end justify-end px-2 animate-fade-in-up"
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
