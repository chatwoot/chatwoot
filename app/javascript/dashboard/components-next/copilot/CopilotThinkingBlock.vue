<script setup>
import Icon from '../../components-next/icon/Icon.vue';
import Spinner from '../../components-next/spinner/Spinner.vue';
defineProps({
  content: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    default: null,
    validator: value => ['active', 'done', 'failed'].includes(value),
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-2 p-3 rounded-lg bg-n-background/50 border border-n-weak hover:bg-n-background/80 transition-colors duration-200"
  >
    <div class="flex items-start gap-2">
      <Spinner
        v-if="status === 'active'"
        :size="16"
        class="mt-0.5 flex-shrink-0 text-n-slate-9"
      />
      <Icon
        v-else-if="status === 'failed'"
        icon="i-lucide-triangle-alert"
        class="w-4 h-4 mt-0.5 flex-shrink-0 text-n-amber-11"
      />
      <Icon
        v-else-if="status === 'done'"
        icon="i-lucide-check"
        class="w-4 h-4 mt-0.5 flex-shrink-0 text-n-teal-10"
      />
      <Icon
        v-else
        icon="i-lucide-sparkles"
        class="w-4 h-4 mt-0.5 flex-shrink-0 text-n-slate-9"
      />
      <div class="text-sm text-n-slate-12">
        {{ content }}
      </div>
    </div>
  </div>
</template>
