<script setup>
defineProps({
  content: {
    type: String,
    required: true,
  },
  reasoning: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="flex flex-col gap-1 px-2 rounded bg-n-background">
    <div
      v-if="reasoning"
      class="text-xs text-n-slate-11 border-t border-n-weak"
    >
      {{ reasoning }}
    </div>
    <p class="text-sm text-n-slate-11">{{ content }}</p>
  </div>
</template>
