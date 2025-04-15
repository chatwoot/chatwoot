<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  withBorder: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    class="flex flex-row"
    :class="{ 'border-t border-n-weak pt-4 mt-2': withBorder }"
  >
    <div class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0">
      <h4 class="text-lg font-medium text-n-slate-12">
        <slot name="title">{{ title }}</slot>
      </h4>
      <p class="text-n-slate-11">
        <slot name="description">{{ description }}</slot>
      </p>
    </div>
    <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%] text-n-slate-12">
      <slot />
    </div>
  </div>
</template>
