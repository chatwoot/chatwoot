<script setup>
import { computed } from 'vue';
import { useSidebarContext } from './provider';
import { useRoute } from 'vue-router';
import Policy from 'dashboard/components/policy.vue';
import SidebarGroupHeader from './SidebarGroupHeader.vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';

const props = defineProps({
  name: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
  to: { type: Object, default: null },
  children: { type: Array, default: undefined },
});

const {
  expandedItem,
  setExpandedItem,
  resolvePath,
  resolvePermissions,
  resolveFeatureFlag,
} = useSidebarContext();

const navigableChildren = computed(() => {
  if (!props.children) {
    return [];
  }

  return props.children.reduce((flattened, child) => {
    if (child.children && child.children.length > 0) {
      flattened.push(...child.children);
    } else {
      flattened.push(child);
    }
    return flattened;
  }, []);
});

const route = useRoute();

const isExpanded = computed(() => expandedItem.value === props.name);
const isExpandable = computed(() => props.children);
const hasChildren = computed(
  () => Array.isArray(props.children) && props.children.length > 0
);
const isActive = computed(
  () => props.to && route.path === resolvePath(props.to)
);

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
</script>

<template>
  <Policy
    as="li"
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
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
      @click="setExpandedItem(name)"
    />
    <ul
      v-if="hasChildren"
      v-show="isExpanded || hasActiveChild"
      class="list-none overflow-scroll m-0 grid sidebar-group-children"
    >
      <template v-for="child in children" :key="child.name">
        <template v-if="child.children">
          <SidebarGroupSeparator
            v-if="isExpanded"
            v-bind="child"
            class="my-1"
          />
          <ul class="m-0 list-none">
            <template v-if="child.children.length">
              <SidebarGroupLeaf
                v-for="l2child in child.children"
                v-show="isExpanded || activeChild?.name === l2child.name"
                v-bind="l2child"
                :key="l2child.name"
                :active="activeChild?.name === l2child.name"
                class="py-0.5 pl-3 relative child-item before:bg-n-slate-3 after:bg-transparent after:border-n-slate-3 ml-3"
              />
            </template>
            <SidebarGroupEmptyLeaf v-else v-show="isExpanded" />
          </ul>
        </template>
        <SidebarGroupLeaf
          v-else
          v-show="isExpanded || activeChild?.name === child.name"
          v-bind="child"
          class="py-0.5 pl-3 relative child-item before:bg-n-slate-3 after:bg-transparent after:border-n-slate-3 ml-3"
          :active="activeChild?.name === child.name"
        />
      </template>
    </ul>
    <ul v-else-if="isExpandable && isExpanded">
      <SidebarGroupEmptyLeaf />
    </ul>
  </Policy>
</template>

<style scoped>
.sidebar-group-children .child-item::before {
  content: '';
  position: absolute;
  width: 0.125rem; /* 0.5px */
  height: 100%;
  left: 0;
}

.sidebar-group-children .child-item:first-child::before {
  border-radius: 4px 4px 0 0;
}

.sidebar-group-children .child-item:last-of-type::before {
  height: 20%;
}

.sidebar-group-children .child-item:last-of-type::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 12px;
  bottom: calc(50% - 2px);
  left: 0;
  border-bottom-width: 0.125rem;
  border-left-width: 0.125rem;
  border-right-width: 0px;
  border-top-width: 0px;
  border-radius: 0 0 0 4px;
}
</style>
