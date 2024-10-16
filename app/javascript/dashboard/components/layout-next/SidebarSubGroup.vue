<script setup>
import { computed } from 'vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useSidebarContext } from './provider';

const props = defineProps({
  isExpanded: { type: Boolean, default: false },
  name: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
});

const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();
const { checkFeatureAllowed, checkPermissions } = usePolicy();

const hasAccessibleItems = computed(() => {
  return props.children.some(child => {
    const permissions = resolvePermissions(child.to);
    const featureFlag = resolveFeatureFlag(child.to);

    return checkPermissions(permissions) && checkFeatureAllowed(featureFlag);
  });
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
  <ul class="m-0 list-none">
    <template v-if="children.length">
      <SidebarGroupLeaf
        v-for="child in children"
        v-show="isExpanded || activeChild?.name === child.name"
        v-bind="child"
        :key="child.name"
        :active="activeChild?.name === child.name"
        class="py-0.5 pl-3 relative child-item before:bg-n-slate-3 after:bg-transparent after:border-n-slate-3 ml-3"
      />
    </template>
    <SidebarGroupEmptyLeaf v-else v-show="isExpanded" />
  </ul>
</template>
