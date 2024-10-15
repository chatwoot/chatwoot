<script setup>
import { computed } from 'vue';
import { useSidebarContext } from './provider';
import { useToggle } from '@vueuse/core';
import { useRoute } from 'vue-router';
import Policy from 'dashboard/components/policy.vue';
import NavGroupHeader from './NavGroupHeader.vue';
import NavGroupLeaf from './NavGroupLeaf.vue';
import NavGroupSeparator from './NavGroupSeparator.vue';
import NavGroupEmptyLeaf from './NavGroupEmptyLeaf.vue';

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

const flattenedChildren = computed(() => {
  const flattend = [];

  // loop over the children, if there are children of children, add a separator entry with no "to" and no "children"
  // just type="separator" and take it's children and appended it to flattend
  props.children.forEach(child => {
    if (child.children) {
      flattend.push({ type: 'separator', name: child.name, icon: child.icon });
      if (child.children.length > 0) {
        flattend.push(...child.children);
      } else {
        flattend.push({ type: 'empty' });
      }
    } else {
      flattend.push(child);
    }
  });

  return flattend;
});

const [transitioning, toggleTransition] = useToggle(false);
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
  return (
    hasChildren.value &&
    flattenedChildren.value.some(child => {
      return child.to?.name === route.name;
    })
  );
});

const activeChild = computed(() => {
  return hasChildren.value
    ? flattenedChildren.value.find(child => {
        return child.to && resolvePath(child.to) === route.path;
      })
    : null;
});

const toggleCollapse = () => {
  toggleTransition(true);
  setExpandedItem(props.name);
};
</script>

<template>
  <Policy
    as="li"
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    class="text-sm cursor-pointer select-none gap-1 grid"
  >
    <NavGroupHeader
      :icon="icon"
      :name="name"
      :to="to"
      :is-active="isActive"
      :has-active-child="hasActiveChild"
      :expandable="hasChildren"
      :is-expanded="isExpanded"
      @click="toggleCollapse()"
    />
    <ul
      v-if="hasChildren && (isExpanded || transitioning || hasActiveChild)"
      class="list-none overflow-scroll m-0 grid"
      @transitionend="toggleTransition(false)"
    >
      <transition
        v-for="(child, index) in flattenedChildren"
        :key="child.name"
        name="fade"
      >
        <NavGroupSeparator
          v-if="child.type === 'separator' && isExpanded"
          v-bind="child"
          :style="{ '--item-index': index }"
          class="my-1"
        />
        <NavGroupEmptyLeaf
          v-else-if="child.type === 'empty' && isExpanded"
          :style="{ '--item-index': index }"
          class="my-1"
        />
        <Policy
          v-else
          v-show="isExpanded || activeChild?.name === child.name"
          as="li"
          :permissions="resolvePermissions(child.to)"
          :feature-flag="resolveFeatureFlag(child.to)"
          :style="{ '--item-index': index }"
          class="py-0.5 pl-3 relative child-item before:bg-n-slate-3 after:bg-transparent after:border-n-slate-3 ml-3"
        >
          <NavGroupLeaf
            v-bind="child"
            :active="activeChild?.name === child.name"
          />
        </Policy>
      </transition>
    </ul>
    <ul v-else-if="isExpandable && isExpanded">
      <NavGroupEmptyLeaf />
    </ul>
  </Policy>
</template>

<style scoped>
.fade-enter-active {
  transition: all 0.15s ease-in-out;
  transition-delay: calc(var(--item-index) * 0.02s);
}

.fade-leave-active {
  transition: all 0.02s ease-out;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.child-item::before {
  content: '';
  position: absolute;
  width: 0.125rem; /* 0.5px */
  height: 100%;
  left: 0;
}

.child-item:first-child::before {
  border-radius: 4px 4px 0 0;
}

.child-item:last-child::before {
  height: 20%;
}

.child-item:last-child::after {
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
