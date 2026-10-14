<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, required: true },
  icon: { type: String, required: true },
});
</script>

<template>
  <div class="grid grid-cols-2 items-center px-3 py-3 border-t border-n-weak">
    <div class="flex items-center gap-2">
      <Icon :icon="icon" class="size-4 text-n-slate-9 flex-shrink-0" />
      <span class="text-n-slate-11">{{ title }}</span>
    </div>
    <slot />
  </div>
</template>
