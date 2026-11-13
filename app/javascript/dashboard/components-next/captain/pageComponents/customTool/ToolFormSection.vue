<script setup>
import { getCurrentInstance } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, required: true },
  summary: { type: String, default: '' },
});

const isOpen = defineModel('open', { type: Boolean, default: false });

const contentId = `tool-form-section-${getCurrentInstance().uid}`;
</script>

<template>
  <section class="border-t border-n-weak">
    <button
      type="button"
      class="flex items-center gap-2 w-full px-0 py-3 text-start outline-none focus-visible:ring-1 focus-visible:ring-n-brand rounded"
      :aria-expanded="isOpen"
      :aria-controls="contentId"
      @click="isOpen = !isOpen"
    >
      <span class="flex-1 text-sm font-medium text-n-slate-12">
        {{ title }}
      </span>
      <span v-if="summary" class="text-xs text-n-slate-11 truncate">
        {{ summary }}
      </span>
      <Icon
        icon="i-lucide-chevron-down"
        class="size-4 text-n-slate-11 transition-transform duration-200"
        :class="{ 'rotate-180': isOpen }"
      />
    </button>
    <div v-show="isOpen" :id="contentId" class="flex flex-col gap-3 pb-4">
      <slot />
    </div>
  </section>
</template>
