<script setup>
import { computed, onMounted, nextTick, ref } from 'vue';
import { useSidebarContext } from './provider';
import { useRoute, useRouter } from 'vue-router';
import Policy from 'dashboard/components/policy.vue';
import SidebarGroupHeader from './SidebarGroupHeader.vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarSubGroup from './SidebarSubGroup.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';

const props = defineProps({
  name: { type: String, required: true },
  label: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
  to: { type: Object, default: null },
  activeOn: { type: Array, default: () => [] },
  children: { type: Array, default: undefined },
  getterKeys: { type: Object, default: () => ({}) },
});

const {
  expandedItem,
  setExpandedItem,
  resolvePath,
  resolvePermissions,
  resolveFeatureFlag,
  isAllowed,
} = useSidebarContext();

// Local state for expansion
const localIsExpanded = ref(false);

const navigableChildren = computed(() => {
  return props.children?.flatMap(child => child.children || child) || [];
});

const route = useRoute();
const router = useRouter();
const isExpandable = computed(() => props.children);
const hasChildren = computed(
  () => Array.isArray(props.children) && props.children.length > 0
);

const accessibleItems = computed(() => {
  if (!hasChildren.value) return [];
  return props.children.filter(child => {
    // If a item has no link, it means it's just a subgroup header
    // So we don't need to check for permissions here, because there's nothing to
    // access here anyway
    return child.to && isAllowed(child.to);
  });
});

const hasAccessibleChildren = computed(() => {
  return accessibleItems.value.length > 0;
});

const isActive = computed(() => {
  if (props.to) {
    if (route.path === resolvePath(props.to)) return true;

    return props.activeOn.includes(route.name);
  }

  return false;
});

// We could use the RouterLink isActive too, but our routes are not always
// nested correctly, so we need to check the active state ourselves
// TODO: Audit the routes and fix the nesting and remove this
const activeChild = computed(() => {
  const pathSame = navigableChildren.value.find(
    child => child.to && route.path === resolvePath(child.to)
  );
  if (pathSame) return pathSame;

  // Rank the activeOn Prop higher than the path match
  // There will be cases where the path name is the same but the params are different
  // So we need to rank them based on the params
  // For example, contacts segment list in the sidebar effectively has the same name
  // But the params are different
  const activeOnPages = navigableChildren.value.filter(child =>
    child.activeOn?.includes(route.name)
  );

  if (activeOnPages.length > 0) {
    const rankedPage = activeOnPages.find(child => {
      return Object.keys(child.to.params)
        .map(key => {
          return String(child.to.params[key]) === String(route.params[key]);
        })
        .every(match => match);
    });

    // If there is no ranked page, return the first activeOn page anyway
    // Since this takes higher precedence over the path match
    // This is not perfect, ideally we should rank each route based on all the techniques
    // and then return the highest ranked one
    // But this is good enough for now
    return rankedPage ?? activeOnPages[0];
  }

  return navigableChildren.value.find(
    child => child.to && route.path.startsWith(resolvePath(child.to))
  );
});

const hasActiveChild = computed(() => {
  return activeChild.value !== undefined;
});

const toggleTrigger = () => {
  // Toggle local state directly
  localIsExpanded.value = !localIsExpanded.value;

  // Keep navigation logic if needed, but remove setExpandedItem call
  if (
    hasAccessibleChildren.value &&
    !localIsExpanded.value && // Check local state
    !hasActiveChild.value
  ) {
    // if closing an inactive group, do nothing extra
  } else if (
    hasAccessibleChildren.value &&
    localIsExpanded.value && // Check local state
    !hasActiveChild.value
  ) {
    // if expanding an inactive group, navigate to first child
    const firstItem = accessibleItems.value[0];
    router.push(firstItem.to);
  }
  // Removed: setExpandedItem(props.name);
};

onMounted(async () => {
  await nextTick();
  if (hasActiveChild.value) {
    // Initialize local state if active
    localIsExpanded.value = true;
    // Optionally still set the shared context if you want the *initial* load
    // to potentially scroll/focus the active item, but subsequent clicks won't affect others.
    // setExpandedItem(props.name);
  }
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Policy
    v-if="!hasChildren || hasAccessibleChildren"
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="grid gap-1 text-sm cursor-pointer select-none"
  >
    <SidebarGroupHeader
      :icon
      :name
      :label
      :to
      :getter-keys="getterKeys"
      :is-active="isActive"
      :has-active-child="hasActiveChild"
      :expandable="hasChildren"
      :is-expanded="localIsExpanded"
      @toggle="toggleTrigger"
    />
    <ul
      v-if="hasChildren"
      v-show="localIsExpanded"
      class="grid m-0 list-none sidebar-group-children"
    >
      <template v-for="child in children" :key="child.name">
        <SidebarSubGroup
          v-if="child.children"
          :label="child.label"
          :icon="child.icon"
          :children="child.children"
          :is-expanded="localIsExpanded"
          :active-child="activeChild"
        />
        <SidebarGroupLeaf
          v-else-if="isAllowed(child.to)"
          v-show="localIsExpanded || activeChild?.name === child.name"
          v-bind="child"
          :active="activeChild?.name === child.name"
        />
      </template>
    </ul>
    <ul v-else-if="isExpandable && localIsExpanded">
      <SidebarGroupEmptyLeaf />
    </ul>
  </Policy>
</template>

<style>
.sidebar-group-children .child-item::before {
  content: '';
  position: absolute;
  width: 0.125rem;
  /* 0.5px */
  height: 100%;
}

.sidebar-group-children .child-item:first-child::before {
  border-radius: 4px 4px 0 0;
}

/* This selects the last child in a group */
/* https://codepen.io/scmmishra/pen/yLmKNLW */
.sidebar-group-children > .child-item:last-child::before,
.sidebar-group-children
  > *:last-child
  > *:last-child
  > .child-item:last-child::before {
  height: 20%;
}

.sidebar-group-children > .child-item:last-child::after,
.sidebar-group-children
  > *:last-child
  > *:last-child
  > .child-item:last-child::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 12px;
  bottom: calc(50% - 2px);
  border-bottom-width: 0.125rem;
  border-left-width: 0.125rem;
  border-right-width: 0px;
  border-top-width: 0px;
  border-radius: 0 0 0 4px;
  left: 0;
}

.app-rtl--wrapper .sidebar-group-children > .child-item:last-child::after,
.app-rtl--wrapper
  .sidebar-group-children
  > *:last-child
  > *:last-child
  > .child-item:last-child::after {
  right: 0;
  border-bottom-width: 0.125rem;
  border-right-width: 0.125rem;
  border-left-width: 0px;
  border-top-width: 0px;
  border-radius: 0 0 4px 0px;
}
</style>
