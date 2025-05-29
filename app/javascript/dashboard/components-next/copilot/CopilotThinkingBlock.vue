<script setup>
import Icon from '../../components-next/icon/Icon.vue';
defineProps({
  content: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-2 p-3 rounded-lg bg-n-background/50 border border-n-weak hover:bg-n-background/80 transition-colors duration-200"
  >
    <div class="flex items-start gap-2">
      <Icon
        icon="i-lucide-sparkles"
        class="w-4 h-4 mt-0.5 flex-shrink-0 text-n-slate-9"
      />
      <div class="text-sm text-n-slate-11">
        {{ content }}
      </div>
    </div>
  </div>
</template>
