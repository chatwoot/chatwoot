<script setup>
import { computed, ref, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import Icon from 'next/icon/Icon.vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';

import { useSidebarContext } from './provider';

const props = defineProps({
  name: { type: String, required: true },
  isExpanded: { type: Boolean, default: false },
  label: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
  sortOptions: { type: Array, default: () => [] },
  activeSort: { type: String, default: '' },
  collapsible: { type: Boolean, default: false },
  showTreeLine: { type: Boolean, default: false },
  endTreeLine: { type: Boolean, default: false },
});

const emit = defineEmits(['update-sort']);

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
const hasActiveChild = computed(() =>
  props.children.some(child => child.name === props.activeChild?.name)
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

const CHILDREN_TRUNK =
  "before:content-[''] before:absolute before:top-0 before:bottom-0 before:w-0.5 before:bg-n-slate-4 before:start-[-0.5rem]";

const hideLeafTreeLine = computed(
  () => props.showTreeLine && !props.isExpanded
);

const toggleSubGroup = () => {
  if (!props.collapsible) return;

  if (isSubGroupExpanded.value) {
    LocalStorage.updateJsonStore(minimizedSectionsKey, storageKey.value, true);
  } else {
    LocalStorage.deleteFromJsonStore(minimizedSectionsKey, storageKey.value);
  }

  minimizedSections.value = getMinimizedSections();
};

const expandSubGroupOnActiveChild = () => {
  if (!props.collapsible || !hasActiveChild.value || isSubGroupExpanded.value) {
    return;
  }

  LocalStorage.deleteFromJsonStore(minimizedSectionsKey, storageKey.value);
  minimizedSections.value = getMinimizedSections();
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

watch([hasActiveChild, storageKey], expandSubGroupOnActiveChild, {
  immediate: true,
});
</script>

<template>
  <li class="group/sidebar-section relative flex flex-col list-none min-w-0">
    <template v-if="hasAccessibleItems">
      <SidebarGroupSeparator
        v-show="isExpanded"
        :label
        :icon
        :collapsible
        :is-expanded="isSubGroupExpanded"
        :show-tree-line="showTreeLine"
        :end-tree-line="endTreeLine"
        :sort-options="sortOptions"
        :active-sort="activeSort"
        class="my-1"
        @toggle="toggleSubGroup"
        @update-sort="sortBy => emit('update-sort', sortBy)"
      />
      <ul
        v-if="children.length"
        class="m-0 list-none reset-base relative group min-w-0"
        :class="[
          { 'ms-5': collapsible },
          showTreeLine && !endTreeLine && CHILDREN_TRUNK,
        ]"
      >
        <div
          ref="scrollableContainer"
          class="min-w-0"
          :class="{
            'max-h-60 overflow-y-scroll no-scrollbar': isScrollable,
          }"
        >
          <SidebarGroupLeaf
            v-for="child in children"
            v-show="shouldShowItem(child)"
            v-bind="child"
            :key="child.name"
            :active="activeChild?.name === child.name"
            :hide-tree-line="hideLeafTreeLine"
            thin-tree-line
          />
        </div>
        <div
          v-if="isScrollable && isExpanded"
          v-show="!scrollEnd"
          class="absolute bg-gradient-to-t from-n-background w-full h-12 to-transparent -bottom-1 pointer-events-none flex items-end justify-end px-2 animate-fade-in-up"
        >
          <Icon
            icon="i-woot-chevrons-down"
            class="w-4 h-6 text-n-slate-9 opacity-50 group-hover:opacity-100"
          />
        </div>
      </ul>
    </template>
  </li>
</template>
