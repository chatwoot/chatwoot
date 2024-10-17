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
      />
    </template>
    <SidebarGroupEmptyLeaf v-else v-show="isExpanded" />
  </ul>
</template>
