<script setup>
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarGroupSeparator from './SidebarGroupSeparator.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';

defineProps({
  isExpanded: { type: Boolean, default: false },
  name: { type: String, required: true },
  icon: { type: [Object, String], required: true },
  children: { type: Array, default: undefined },
  activeChild: { type: Object, default: undefined },
});
</script>

<template>
  <SidebarGroupSeparator v-show="isExpanded" :name :icon class="my-1" />
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
