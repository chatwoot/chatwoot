<script setup>
import Icon from './Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { useSidebarContext } from './provider';

defineProps({
  name: {
    type: String,
    required: true,
  },
  to: {
    type: [String, Object],
    required: true,
  },
  icon: {
    type: [String, Object],
    default: null,
  },
  active: {
    type: Boolean,
    default: false,
  },
});

const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();
</script>

<template>
  <Policy
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="py-0.5 pl-3 relative child-item before:bg-n-slate-3 after:bg-transparent after:border-n-slate-3 ml-3"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="name"
      class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg max-w-[151px] hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70 group"
      :class="{
        'text-n-blue bg-n-alpha-2 font-medium active': active,
      }"
    >
      <Icon v-if="icon" :icon="icon" class="size-4 inline-block" />

      <div class="flex-1 truncate min-w-0">{{ name }}</div>
    </component>
  </Policy>
</template>

<style scoped>
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

.last-child-item::before {
  height: 20%;
}

.last-child-item::after {
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
