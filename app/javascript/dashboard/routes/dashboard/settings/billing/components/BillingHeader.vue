<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="grid grid-cols-[1fr_auto] gap-4 items-center">
    <div>
      <span class="text-sm font-medium text-n-slate-12">
        {{ title }}
      </span>
      <p v-if="description" class="text-sm mt-0.5 text-n-slate-11">
        {{ description }}
      </p>
    </div>
    <slot />
  </div>
</template>
