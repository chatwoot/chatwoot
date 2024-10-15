<script setup>
import Icon from './Icon.vue';

defineProps({
  to: {
    type: [Object, String],
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
  expandable: {
    type: Boolean,
    default: false,
  },
  isExpanded: {
    type: Boolean,
    default: false,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
  hasActiveChild: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <component
    :is="to ? 'router-link' : 'div'"
    class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-8"
    role="button"
    :to="to"
    :title="name"
    :class="{
      'text-n-blue bg-n-alpha-2 font-medium': isActive && !hasActiveChild,
      'text-n-slate-12 font-medium': hasActiveChild,
      'text-n-slate-11 hover:bg-n-alpha-2': !isActive && !hasActiveChild,
    }"
  >
    <Icon v-if="icon" :icon="icon" class="size-4" />
    <span class="text-sm font-medium leading-5 flex-grow">
      {{ name }}
    </span>
    <span
      v-if="expandable"
      v-show="isExpanded"
      class="i-lucide-chevron-up size-3"
    />
  </component>
</template>
