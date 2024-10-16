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
