<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  to: { type: [Object, String], default: '' },
  label: { type: String, default: '' },
  icon: { type: [String, Object], default: '' },
  expandable: { type: Boolean, default: false },
  isExpanded: { type: Boolean, default: false },
  isActive: { type: Boolean, default: false },
  hasActiveChild: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle']);
</script>

<template>
  <component
    :is="to ? 'router-link' : 'div'"
    class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-8"
    role="button"
    :to="to"
    :title="label"
    :class="{
      'n-blue-text bg-n-alpha-2 font-medium': isActive && !hasActiveChild,
      'text-n-slate-12 font-medium': hasActiveChild,
      'text-n-slate-11 hover:bg-n-alpha-2': !isActive && !hasActiveChild,
    }"
    @click.stop="emit('toggle')"
  >
    <Icon v-if="icon" :icon="icon" class="size-4" />
    <span class="text-sm font-medium leading-5 flex-grow">
      {{ label }}
    </span>
    <span
      v-if="expandable"
      v-show="isExpanded"
      class="i-lucide-chevron-up size-3"
      @click.stop="emit('toggle')"
    />
  </component>
</template>
