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
  <header class="mb-3 flex items-start justify-between gap-2">
    <div>
      <h3 class="m-0 text-sm font-semibold text-n-slate-12">
        {{ title }}
      </h3>
      <p v-if="description" class="m-0 mt-1 text-xs text-n-slate-11">
        {{ description }}
      </p>
    </div>
    <slot />
  </header>
</template>
