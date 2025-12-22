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
      <h4 v-if="title" class="text-lg font-medium text-n-slate-12">
        {{ title }}
      </h4>
      <div class="flex flex-row items-center justify-between">
        <div class="flex-grow h-px bg-n-weak" />
      </div>
      <p v-if="description" class="mb-0 text-sm font-normal text-n-slate-12">
        {{ description }}
      </p>
    </div>
    <div class="flex flex-col w-full gap-6">
      <slot />
    </div>
  </div>
</template>
