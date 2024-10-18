<script setup>
import { computed, watch } from 'vue';
import { useParentElement } from '@vueuse/core';
import { useSidebarContext } from './provider';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useRoute } from 'vue-router';
import Policy from 'dashboard/components/policy.vue';
import SidebarGroupHeader from './SidebarGroupHeader.vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarSubGroup from './SidebarSubGroup.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';

const props = defineProps({
  name: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
  to: { type: Object, default: null },
  activeOn: { type: Array, default: () => [] },
  children: { type: Array, default: undefined },
});

const {
  expandedItem,
  setExpandedItem,
  resolvePath,
  resolvePermissions,
  resolveFeatureFlag,
} = useSidebarContext();

const { checkFeatureAllowed, checkPermissions } = usePolicy();

const parentEl = useParentElement();

const locateLastChild = () => {
  parentEl.value?.querySelectorAll('.child-item').forEach((child, index) => {
    if (index === parentEl.value.querySelectorAll('.child-item').length - 1) {
      child.classList.add('last-child-item');
    }
  });
};

const navigableChildren = computed(() => {
  return props.children?.flatMap(child => child.children || child) || [];
});

const route = useRoute();

const isExpanded = computed(() => expandedItem.value === props.name);
const isExpandable = computed(() => props.children);
const hasChildren = computed(
  () => Array.isArray(props.children) && props.children.length > 0
);

const accessibleItems = computed(() => {
  if (!hasChildren.value) return [];

  return props.children.filter(child => {
    const permissions = resolvePermissions(child.to);
    const featureFlag = resolveFeatureFlag(child.to);

    return checkPermissions(permissions) && checkFeatureAllowed(featureFlag);
  });
});

const hasAccessibleItems = computed(() => {
  // default true so that rendering is not blocked
  if (!hasChildren.value) return true;

  return accessibleItems.value.length > 0;
});

const isActive = computed(() => {
  if (props.to) {
    if (route.path === resolvePath(props.to)) return true;

    return props.activeOn.includes(route.name);
  }

  return false;
});

const hasActiveChild = computed(() => {
  return navigableChildren.value.some(child => {
    return child.to?.name === route.name;
  });
});

const activeChild = computed(() => {
  return navigableChildren.value.find(child => {
    return child.to && resolvePath(child.to) === route.path;
  });
});

watch([isExpanded, hasActiveChild, isActive], locateLastChild, {
  immediate: true,
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Policy
    v-if="hasAccessibleItems"
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="text-sm cursor-pointer select-none gap-1 grid"
  >
    <SidebarGroupHeader
      :icon="icon"
      :name="name"
      :to="to"
      :is-active="isActive"
      :has-active-child="hasActiveChild"
      :expandable="hasChildren"
      :is-expanded="isExpanded"
      @toggle="setExpandedItem(name)"
    />
    <ul
      v-if="hasChildren"
      v-show="isExpanded || hasActiveChild"
      class="list-none overflow-scroll m-0 grid sidebar-group-children"
    >
      <template v-for="child in children" :key="child.name">
        <SidebarSubGroup
          v-if="child.children"
          v-bind="child"
          :is-expanded="isExpanded"
          :active-child="activeChild"
        />
        <SidebarGroupLeaf
          v-else
          v-show="isExpanded || activeChild?.name === child.name"
          v-bind="child"
          :active="activeChild?.name === child.name"
        />
      </template>
    </ul>
    <ul v-else-if="isExpandable && isExpanded">
      <SidebarGroupEmptyLeaf />
    </ul>
  </Policy>
</template>
