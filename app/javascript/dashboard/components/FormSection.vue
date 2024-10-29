<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex flex-col items-start w-full gap-6">
    <div class="flex flex-col w-full gap-4">
      <h4 v-if="title" class="text-lg font-medium text-ash-900">
        {{ title }}
      </h4>
      <div class="flex flex-row items-center justify-between">
        <div class="flex-grow h-px bg-ash-200" />
      </div>
      <p v-if="description" class="mb-0 text-sm font-normal text-ash-900">
        {{ description }}
      </p>
    </div>
    <div class="flex flex-col w-full gap-6">
      <slot />
    </div>
  </div>
</template>
