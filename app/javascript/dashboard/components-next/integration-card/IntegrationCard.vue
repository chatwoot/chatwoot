<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  icon: { type: [String, Object, Function], required: true },
  title: { type: String, required: true },
  description: { type: String, default: '' },
});
</script>

<template>
  <div
    class="flex flex-col gap-4 p-4 rounded-xl outline outline-1 outline-n-weak"
  >
    <div class="flex items-start gap-3">
      <div
        class="flex items-center justify-center rounded-lg size-9 shrink-0 bg-n-alpha-2 text-n-slate-12"
      >
        <Icon :icon="icon" class="size-5" />
      </div>
      <div class="flex flex-col gap-0.5">
        <h6 class="text-sm font-medium text-n-slate-12">{{ title }}</h6>
        <span v-if="description" class="text-sm text-n-slate-11">
          {{ description }}
        </span>
      </div>
    </div>
    <slot />
  </div>
</template>
