<script setup>
defineProps({
  headerTitle: {
    required: true,
    type: String,
  },
});
</script>

<template>
  <div class="flex items-center justify-between w-full h-20 gap-2">
    <span class="text-xl font-medium text-n-slate-12">
      {{ headerTitle }}
    </span>
    <slot />
  </div>
</template>
